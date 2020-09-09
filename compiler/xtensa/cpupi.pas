{
    Copyright (c) 2002 by Florian Klaempfl

    This unit contains the CPU specific part of tprocinfo

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

 ****************************************************************************
}

{ This unit contains the CPU specific part of tprocinfo. }
unit cpupi;

{$i fpcdefs.inc}

  interface

    uses
       cutils,globtype,
       cpubase,
       cgbase,aasmdata,
       procinfo,cpuinfo,psub;

    type
      txtensaprocinfo = class(tcgprocinfo)
        callins,callxins : TAsmOp;
        stackframesize,
        stackpaddingreg: TSuperRegister;

        needs_frame_pointer: boolean;
        { highest N used in a call instruction }
        maxcall : Byte;
        // procedure handle_body_start;override;
        // procedure after_pass1;override;
        constructor create(aparent: tprocinfo); override;
        procedure set_first_temp_offset;override;
        function calc_stackframe_size:longint;override;
        procedure init_framepointer;override;
        procedure generate_parameter_info;override;
      end;


  implementation

    uses
       globals,systems,
       verbose,
       tgobj,
       symconst,symtype,symsym,symcpu,symdef,
       paramgr,
       cgutils,
       cgobj,
       defutil,
       aasmcpu;     

    constructor txtensaprocinfo.create(aparent: tprocinfo);
      begin
        inherited create(aparent);
        maxpushedparasize:=0;
        if target_info.abi=abi_xtensa_windowed then
          begin
            callins:=A_CALL8;
            callxins:=A_CALLX8;
            { set properly }
            maxcall:=8;

            { we do not use a frame pointer for the windowed abi }
            framepointer:=NR_STACK_POINTER_REG;
          end
        else
          begin
            callins:=A_CALL0;
            callxins:=A_CALLX0;
            maxcall:=0;
            { we do not use a frame pointer }
            framepointer:=NR_STACK_POINTER_REG;
          end;
      end;


    procedure txtensaprocinfo.set_first_temp_offset;
      var
        localsize : aint;
        i : longint;
      begin
        maxpushedparasize:=Align(maxpushedparasize,target_info.alignment.localalignmax);
        tg.setfirsttemp(maxpushedparasize);

        if po_nostackframe in procdef.procoptions then
          exit;

        { estimate stack frame size }
        if pi_estimatestacksize in flags then
          begin
            stackframesize:=align(maxpushedparasize,target_info.alignment.localalignmax);
            localsize:=0;
            for i:=0 to procdef.localst.SymList.Count-1 do
              if tsym(procdef.localst.SymList[i]).typ=localvarsym then
                begin
                  localsize:=align(localsize,tabstractnormalvarsym(procdef.localst.SymList[i]).vardef.alignment);
                  inc(localsize,tabstractnormalvarsym(procdef.localst.SymList[i]).getsize);
                end;
            inc(stackframesize,localsize);
            stackframesize:=align(stackframesize,target_info.alignment.localalignmax);

            localsize:=0;
            for i:=0 to procdef.parast.SymList.Count-1 do
              if tsym(procdef.parast.SymList[i]).typ=paravarsym then
                begin
                  if tabstractnormalvarsym(procdef.parast.SymList[i]).varspez in [vs_var,vs_out,vs_constref] then
                    begin
                      localsize:=align(localsize,4);
                      inc(localsize,4)
                    end
                  else if is_open_string(tabstractnormalvarsym(procdef.parast.SymList[i]).vardef) then
                    inc(localsize,256)
                  else
                    begin
                      localsize:=align(localsize,tparavarsym(procdef.parast.SymList[i]).paraloc[calleeside].alignment);
                      { getsize returns 0 for e.g. open arrays, however, they require a pointer at the stack, so
                        allocate one pointer }
                      if tabstractnormalvarsym(procdef.parast.SymList[i]).getsize=0 then
                        inc(localsize,voidpointertype.size)
                      else
                        inc(localsize,tabstractnormalvarsym(procdef.parast.SymList[i]).getsize);
                    end;
                end;
            inc(stackframesize,localsize);

            stackframesize:=align(stackframesize,target_info.alignment.localalignmax);
            inc(stackframesize,estimatedtempsize);

            stackframesize:=align(stackframesize,4);
            if pi_needs_implicit_finally in flags then
              inc(stackframesize,40);

            if pi_uses_exceptions in flags then
              inc(stackframesize,40);

            if procdef.proctypeoption in [potype_constructor] then
              inc(stackframesize,40*2);

            { default spill area }
            inc(stackframesize,4*4);

            { additional spill area? }
            if pi_do_call in current_procinfo.flags then
              inc(stackframesize,maxcall*4);

            stackframesize:=Align(stackframesize,target_info.alignment.localalignmax);
          end;
      end;


    function txtensaprocinfo.calc_stackframe_size:longint;
      var
         r, extra: byte;
         regs: tcpuregisterset;
      begin
        if pi_estimatestacksize in flags then
          begin
            if pi_do_call in current_procinfo.flags then
              extra:=maxcall*4+4*4
            else
              extra:=4*4;
            if Align(tg.direction*tg.lasttemp,max(current_settings.alignment.localalignmin,4))+extra>stackframesize then
              InternalError(2020082801);
            result:=stackframesize
          end
        else
          result:=Align(tg.direction*tg.lasttemp,max(current_settings.alignment.localalignmin,4))+maxpushedparasize;
      end;


    procedure txtensaprocinfo.generate_parameter_info;
      begin
       tcpuprocdef(procdef).total_stackframe_size:=stackframesize;
       inherited generate_parameter_info;
      end;


    procedure txtensaprocinfo.init_framepointer;
      begin
        if target_info.abi=abi_xtensa_call0 then
          begin
            RS_FRAME_POINTER_REG:=RS_A15;
            NR_FRAME_POINTER_REG:=NR_A15;
          end
        else
          begin
            { a frame pointer would be only needed if we do an "alloca" }
            RS_FRAME_POINTER_REG:=RS_A15;
            NR_FRAME_POINTER_REG:=NR_A15;
          end;
      end;

begin
   cprocinfo:=txtensaprocinfo;
end.

