unit tcresolvegenerics;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, testregistry, tcresolver, PasResolveEval, PParser;

type

  { TTestResolveGenerics }

  TTestResolveGenerics = Class(TCustomTestResolver)
  Published
    // generic types
    procedure TestGen_MissingTemplateFail;
    procedure TestGen_VarTypeWithoutSpecializeFail;
    procedure TestGen_GenTypeWithWrongParamCountFail;
    procedure TestGen_GenericNotFoundFail;
    procedure TestGen_SameNameSameParamCountFail;
    procedure TestGen_TypeAliasWithoutSpecializeFail;

    // constraints
    procedure TestGen_ConstraintStringFail;
    procedure TestGen_ConstraintMultiClassFail;
    procedure TestGen_ConstraintRecordExpectedFail;
    procedure TestGen_ConstraintClassRecordFail;
    procedure TestGen_ConstraintRecordClassFail;
    procedure TestGen_ConstraintArrayFail;
    procedure TestGen_ConstraintConstructor;
    // ToDo: constraint T:Unit2.TBird
    // ToDo: constraint T:Unit2.TGen<word>
    procedure TestGen_TemplNameEqTypeNameFail;
    procedure TestGen_ConstraintInheritedMissingRecordFail;
    procedure TestGen_ConstraintInheritedMissingClassTypeFail;
    procedure TestGen_ConstraintMultiParam;
    procedure TestGen_ConstraintMultiParamClassMismatch;
    procedure TestGen_ConstraintClassType_DotIsAsTypeCast;

    // generic record
    procedure TestGen_RecordLocalNameDuplicateFail;
    procedure TestGen_Record;
    procedure TestGen_RecordDelphi;
    procedure TestGen_RecordNestedSpecialized;
    procedure TestGen_Record_SpecializeSelfInsideFail;
    procedure TestGen_RecordAnoArray;
    // ToDo: unitname.specialize TBird<word>.specialize
    procedure TestGen_RecordNestedSpecialize;

    // generic class
    procedure TestGen_Class;
    procedure TestGen_ClassDelphi;
    procedure TestGen_ClassForward;
    procedure TestGen_ClassForwardConstraints;
    procedure TestGen_ClassForwardConstraintNameMismatch;
    procedure TestGen_ClassForwardConstraintKeywordMismatch;
    procedure TestGen_ClassForwardConstraintTypeMismatch;
    procedure TestGen_ClassForward_Circle;
    procedure TestGen_Class_RedeclareInUnitImplFail;
    procedure TestGen_Class_AnotherInUnitImpl;
    procedure TestGen_Class_Method;
    procedure TestGen_Class_MethodOverride;
    procedure TestGen_Class_MethodDelphi;
    procedure TestGen_Class_MethodDelphiTypeParamMissing;
    procedure TestGen_Class_MethodImplConstraintFail;
    procedure TestGen_Class_MethodImplTypeParamNameMismatch;
    procedure TestGen_Class_SpecializeSelfInside;
    procedure TestGen_Class_GenAncestor;
    procedure TestGen_Class_AncestorSelfFail;
    procedure TestGen_ClassOfSpecializeFail;
    // ToDo: UnitA.impl uses UnitB.intf uses UnitA.intf, UnitB has specialize of UnitA
    procedure TestGen_Class_NestedType;
    procedure TestGen_Class_NestedRecord;
    procedure TestGen_Class_NestedClass;
    procedure TestGen_Class_Enums_NotPropagating;
    procedure TestGen_Class_Self;
    procedure TestGen_Class_MemberTypeConstructor;
    procedure TestGen_Class_List;

    // generic external class
    procedure TestGen_ExtClass_Array;

    // generic interface
    procedure TestGen_ClassInterface;
    procedure TestGen_ClassInterface_Method;

    // generic array
    procedure TestGen_DynArray;
    procedure TestGen_StaticArray;
    procedure TestGen_Array_Anoynmous;

    // generic procedure type
    procedure TestGen_ProcType;

    // pointer of generic
    procedure TestGen_PointerDirectSpecializeFail;

    // ToDo: helpers for generics

    // generic functions
    procedure TestGen_GenericFunction; // ToDo
    // ToDo: generic class method overload <T> <S,T>
    // ToDo: procedure TestGen_GenMethod_ClassConstructorFail;

    // generic statements
    procedure TestGen_LocalVar;
    procedure TestGen_Statements;
    procedure TestGen_InlineSpecializeExpr;
    // ToDo: for-in
    procedure TestGen_TryExcept;
    // ToDo: call
    // ToTo: nested proc
  end;

implementation

{ TTestResolveGenerics }

procedure TTestResolveGenerics.TestGen_MissingTemplateFail;
begin
  StartProgram(false);
  Add([
  'type generic g< > = array of word;',
  'begin',
  '']);
  CheckParserException('Expected "Identifier"',nParserExpectTokenError);
end;

procedure TTestResolveGenerics.TestGen_VarTypeWithoutSpecializeFail;
begin
  StartProgram(false);
  Add([
  'type generic TBird<T> = record end;',
  'var b: TBird;',
  'begin',
  '']);
  CheckResolverException('Generics without specialization cannot be used as a type for a variable',
    nGenericsWithoutSpecializationAsType);
end;

procedure TTestResolveGenerics.TestGen_GenTypeWithWrongParamCountFail;
begin
  StartProgram(false);
  Add([
  'type generic TBird<T> = record end;',
  'var b: TBird<word, byte>;',
  'begin',
  '']);
  CheckResolverException('identifier not found "TBird<,>"',
    nIdentifierNotFound);
end;

procedure TTestResolveGenerics.TestGen_GenericNotFoundFail;
begin
  StartProgram(false);
  Add([
  '{$mode objfpc}',
  'type',
  '  TBird = specialize TAnimal<word>;',
  'begin',
  '']);
  CheckResolverException('identifier not found "TAnimal<>"',
    nIdentifierNotFound);
end;

procedure TTestResolveGenerics.TestGen_SameNameSameParamCountFail;
begin
  StartProgram(false);
  Add([
  '{$mode delphi}',
  'type',
  '  TBird<S,T> = record w: T; end;',
  '  TBird<X,Y> = record f: X; end;',
  'begin',
  '']);
  CheckResolverException('Duplicate identifier "TBird" at afile.pp(4,8)',
    nDuplicateIdentifier);
end;

procedure TTestResolveGenerics.TestGen_TypeAliasWithoutSpecializeFail;
begin
  StartProgram(false);
  Add([
  '{$mode delphi}',
  'type',
  '  TBird<T> = record w: T; end;',
  '  TBirdAlias = TBird;',
  'begin',
  '']);
  CheckResolverException('type expected, but TBird<> found',
    nXExpectedButYFound);
end;

procedure TTestResolveGenerics.TestGen_ConstraintStringFail;
begin
  StartProgram(false);
  Add([
  'generic function DoIt<T:string>(a: T): T;',
  'begin',
  '  Result:=a;',
  'end;',
  'begin',
  '']);
  CheckResolverException('"String" is not a valid constraint',
    nXIsNotAValidConstraint);
end;

procedure TTestResolveGenerics.TestGen_ConstraintMultiClassFail;
begin
  StartProgram(false);
  Add([
  '{$mode objfpc}',
  'type',
  '  TObject = class end;',
  '  TBird = class end;',
  '  TBear = class end;',
  'generic function DoIt<T: TBird, TBear>(a: T): T;',
  'begin',
  '  Result:=a;',
  'end;',
  'begin',
  '']);
  CheckResolverException('"TBird" constraint and "TBear" constraint cannot be specified together',
    nConstraintXAndConstraintYCannotBeTogether);
end;

procedure TTestResolveGenerics.TestGen_ConstraintRecordExpectedFail;
begin
  StartProgram(false);
  Add([
  '{$mode objfpc}',
  'type',
  '  generic TBird<T:record> = record v: T; end;',
  'var r: specialize TBird<word>;',
  'begin',
  '']);
  CheckResolverException('record type expected, but Word found',
    nXExpectedButYFound);
end;

procedure TTestResolveGenerics.TestGen_ConstraintClassRecordFail;
begin
  StartProgram(false);
  Add([
  '{$mode objfpc}',
  'type',
  '  TRec = record end;',
  '  generic TBird<T:class> = record v: T; end;',
  'var r: specialize TBird<TRec>;',
  'begin',
  '']);
  CheckResolverException('class type expected, but TRec found',
    nXExpectedButYFound);
end;

procedure TTestResolveGenerics.TestGen_ConstraintRecordClassFail;
begin
  StartProgram(false);
  Add([
  '{$mode objfpc}',
  'type',
  '  TObject = class end;',
  '  generic TBird<T:record> = record v: T; end;',
  'var r: specialize TBird<TObject>;',
  'begin',
  '']);
  CheckResolverException('record type expected, but TObject found',
    nXExpectedButYFound);
end;

procedure TTestResolveGenerics.TestGen_ConstraintArrayFail;
begin
  StartProgram(false);
  Add([
  '{$mode objfpc}',
  'type',
  '  TArr = array of word;',
  '  generic TBird<T:TArr> = record v: T; end;',
  'begin',
  '']);
  CheckResolverException('"array of Word" is not a valid constraint',
    nXIsNotAValidConstraint);
end;

procedure TTestResolveGenerics.TestGen_ConstraintConstructor;
begin
  StartProgram(true,[supTObject]);
  Add([
  '{$mode objfpc}',
  'type',
  '  generic TBird<T:constructor> = class',
  '    o: T;',
  '    procedure Fly;',
  '  end;',
  '  TAnt = class end;',
  'var a: specialize TBird<TAnt>;',
  'procedure TBird.Fly;',
  'begin',
  '  o:=T.Create;',
  'end;',
  'begin',
  '']);
  ParseProgram;
end;

procedure TTestResolveGenerics.TestGen_TemplNameEqTypeNameFail;
begin
  StartProgram(false);
  Add([
  '{$mode objfpc}',
  'type',
  '  generic TBird<TBird> = record v: T; end;',
  'var r: specialize TBird<word>;',
  'begin',
  '']);
  CheckResolverException('Duplicate identifier "TBird" at afile.pp(4,16)',
    nDuplicateIdentifier);
end;

procedure TTestResolveGenerics.TestGen_ConstraintInheritedMissingRecordFail;
begin
  StartProgram(false);
  Add([
  '{$mode objfpc}',
  'type',
  '  TObject = class end;',
  '  generic TBird<T: record> = class v: T; end;',
  '  generic TEagle<U> = class(TBird<U>)',
  '  end;',
  'begin',
  '']);
  CheckResolverException('Type parameter "U" is missing constraint "record"',
    nTypeParamXIsMissingConstraintY);
end;

procedure TTestResolveGenerics.TestGen_ConstraintInheritedMissingClassTypeFail;
begin
  StartProgram(false);
  Add([
  '{$mode objfpc}',
  'type',
  '  TObject = class end;',
  '  TAnt = class end;',
  '  generic TBird<T: TAnt> = class v: T; end;',
  '  generic TEagle<U> = class(TBird<U>)',
  '  end;',
  'begin',
  '']);
  CheckResolverException('Type parameter "U" is not compatible with type "TAnt"',
    nTypeParamXIsNotCompatibleWithY);
end;

procedure TTestResolveGenerics.TestGen_ConstraintMultiParam;
begin
  StartProgram(false);
  Add([
  '{$mode objfpc}',
  'type',
  '  TObject = class end;',
  '  TAnt = class end;',
  '  generic TBird<S,T: TAnt> = class',
  '    x: S;',
  '    y: T;',
  '  end;',
  '  TRedAnt = class(TAnt) end;',
  '  TEagle = specialize TBird<TRedAnt,TAnt>;',
  'begin',
  '']);
  ParseProgram;
end;

procedure TTestResolveGenerics.TestGen_ConstraintMultiParamClassMismatch;
begin
  StartProgram(false);
  Add([
  '{$mode objfpc}',
  'type',
  '  TObject = class end;',
  '  TAnt = class end;',
  '  TRedAnt = class(TAnt) end;',
  '  generic TBird<S,T: TRedAnt> = class',
  '    x: S;',
  '    y: T;',
  '  end;',
  '  TEagle = specialize TBird<TRedAnt,TAnt>;',
  'begin',
  '']);
  CheckResolverException('Incompatible types: got "TAnt" expected "TRedAnt"',
    nIncompatibleTypesGotExpected);
end;

procedure TTestResolveGenerics.TestGen_ConstraintClassType_DotIsAsTypeCast;
begin
  StartProgram(false);
  Add([
  '{$mode objfpc}',
  'type',
  '  TObject = class end;',
  '  TAnt = class',
  '    procedure Run; external; overload;',
  '  end;',
  '  TRedAnt = class(TAnt)',
  '    procedure Run(w: word); external; overload;',
  '  end;',
  '  generic TBird<T: TRedAnt> = class',
  '    y: T;',
  '    procedure Fly;',
  '  end;',
  '  TFireAnt = class(TRedAnt);',
  '  generic TEagle<U: TRedAnt> = class(TBird<U>) end;',
  '  TRedEagle = specialize TEagle<TRedAnt>;',
  'procedure TBird.Fly;',
  'var f: TFireAnt;',
  'begin',
  '  y.Run;',
  '  y.Run(3);',
  '  if y is TFireAnt then',
  '    f:=y as TFireAnt;',
  '  f:=TFireAnt(y);',
  '  y:=T(f);',
  'end;',
  'begin',
  '']);
  ParseProgram;
end;

procedure TTestResolveGenerics.TestGen_RecordLocalNameDuplicateFail;
begin
  StartProgram(false);
  Add([
  '{$mode objfpc}',
  'type',
  '  generic TBird<T> = record T: word; end;',
  'begin',
  '']);
  CheckResolverException('Duplicate identifier "T" at afile.pp(4,18)',
    nDuplicateIdentifier);
end;

procedure TTestResolveGenerics.TestGen_Record;
begin
  StartProgram(false);
  Add([
  '{$mode objfpc}',
  'type',
  '  {#Typ}T = word;',
  '  generic TRec<{#Templ}T> = record',
  '    {=Templ}v: T;',
  '  end;',
  'var',
  '  r: specialize TRec<word>;',
  '  {=Typ}w: T;',
  'begin',
  '  r.v:=w;',
  '']);
  ParseProgram;
end;

procedure TTestResolveGenerics.TestGen_RecordDelphi;
begin
  StartProgram(false);
  Add([
  '{$mode delphi}',
  'type',
  '  {#Typ}T = word;',
  '  TRec<{#Templ}T> = record',
  '    {=Templ}v: T;',
  '  end;',
  'var',
  '  r: TRec<word>;',
  '  {=Typ}w: T;',
  'begin',
  '  r.v:=w;',
  '']);
  ParseProgram;
end;

procedure TTestResolveGenerics.TestGen_RecordNestedSpecialized;
begin
  StartProgram(false);
  Add([
  '{$mode objfpc}',
  'type',
  '  TObject = class end;',
  '  generic TBird<T> = class v: T; end;',
  '  generic TFish<T:class> = record v: T; end;',
  'var f: specialize TFish<specialize TBird<word>>;',
  'begin',
  '']);
  ParseProgram;
end;

procedure TTestResolveGenerics.TestGen_Record_SpecializeSelfInsideFail;
begin
  StartProgram(false);
  Add([
  '{$mode objfpc}',
  'type',
  '  generic TBird<T> = record',
  '    v: specialize TBird<word>;',
  '  end;',
  'begin',
  '']);
  CheckResolverException('type "TBird<>" is not yet completely defined',
    nTypeXIsNotYetCompletelyDefined);
end;

procedure TTestResolveGenerics.TestGen_RecordAnoArray;
begin
  StartProgram(false);
  Add([
  '{$mode objfpc}',
  'type',
  '  generic TBird<T> = record v: T; end;',
  'var',
  '  a: specialize TBird<array of word>;',
  '  b: specialize TBird<array of word>;',
  'begin',
  '  a:=b;',
  '']);
  ParseProgram;
end;

procedure TTestResolveGenerics.TestGen_RecordNestedSpecialize;
begin
  StartProgram(false);
  Add([
  '{$mode objfpc}',
  'type',
  '  generic TBird<T> = record v: T; end;',
  'var',
  '  a: specialize TBird<specialize TBird<word>>;',
  'begin',
  '  a.v.v:=3;',
  '']);
  ParseProgram;
end;

procedure TTestResolveGenerics.TestGen_Class;
begin
  StartProgram(false);
  Add([
  '{$mode objfpc}',
  'type',
  '  TObject = class end;',
  '  {#Typ}T = word;',
  '  generic TBird<{#Templ}T> = class',
  '    {=Templ}v: T;',
  '  end;',
  'var',
  '  b: specialize TBird<word>;',
  '  {=Typ}w: T;',
  'begin',
  '  b.v:=w;',
  '']);
  ParseProgram;
end;

procedure TTestResolveGenerics.TestGen_ClassDelphi;
begin
  StartProgram(false);
  Add([
  '{$mode delphi}',
  'type',
  '  TObject = class end;',
  '  {#Typ}T = word;',
  '  TBird<{#Templ}T> = class',
  '    {=Templ}v: T;',
  '  end;',
  'var',
  '  b: TBird<word>;',
  '  {=Typ}w: T;',
  'begin',
  '  b.v:=w;',
  '']);
  ParseProgram;
end;

procedure TTestResolveGenerics.TestGen_ClassForward;
begin
  StartProgram(false);
  Add([
  '{$mode objfpc}',
  'type',
  '  TObject = class end;',
  '  {#Typ}T = word;',
  '  generic TBird<{#Templ_Forward}T> = class;',
  '  TRec = record',
  '    b: specialize TBird<T>;',
  '  end;',
  '  generic TBird<{#Templ}T> = class',
  '    {=Templ}v: T;',
  '    r: TRec;',
  '  end;',
  'var',
  '  s: TRec;',
  '  {=Typ}w: T;',
  'begin',
  '  s.b.v:=w;',
  '  s.b.r:=s;',
  '']);
  ParseProgram;
end;

procedure TTestResolveGenerics.TestGen_ClassForwardConstraints;
begin
  StartProgram(false);
  Add([
  '{$mode objfpc}',
  'type',
  '  TObject = class end;',
  '  TAnt = class end;',
  '  generic TBird<T: class; U; V: TAnt> = class;',
  '  TRec = record',
  '    b: specialize TBird<TAnt,word,TAnt>;',
  '  end;',
  '  generic TBird<T: class; U; V: TAnt> = class',
  '    i: U;',
  '    r: TRec;',
  '  end;',
  'var',
  '  s: TRec;',
  '  w: word;',
  'begin',
  '  s.b.i:=w;',
  '  s.b.r:=s;',
  '']);
  ParseProgram;
end;

procedure TTestResolveGenerics.TestGen_ClassForwardConstraintNameMismatch;
begin
  StartProgram(false);
  Add([
  '{$mode objfpc}',
  'type',
  '  TObject = class end;',
  '  generic TBird<T> = class;',
  '  generic TBird<U> = class',
  '    i: U;',
  '  end;',
  'begin',
  '']);
  CheckResolverException('Declaration of "U" differs from previous declaration at afile.pp(5,18)',
    nDeclOfXDiffersFromPrevAtY);
end;

procedure TTestResolveGenerics.TestGen_ClassForwardConstraintKeywordMismatch;
begin
  StartProgram(false);
  Add([
  '{$mode objfpc}',
  'type',
  '  TObject = class end;',
  '  generic TBird<T: class, constructor> = class;',
  '  generic TBird<U: class> = class',
  '    i: U;',
  '  end;',
  'begin',
  '']);
  CheckResolverException('Declaration of "U" differs from previous declaration at afile.pp(5,18)',
    nDeclOfXDiffersFromPrevAtY);
end;

procedure TTestResolveGenerics.TestGen_ClassForwardConstraintTypeMismatch;
begin
  StartProgram(false);
  Add([
  '{$mode objfpc}',
  'type',
  '  TObject = class end;',
  '  TAnt = class end;',
  '  TFish = class end;',
  '  generic TBird<T: TAnt> = class;',
  '  generic TBird<T: TFish> = class',
  '    i: U;',
  '  end;',
  'begin',
  '']);
  CheckResolverException('Declaration of "T" differs from previous declaration at afile.pp(7,20)',
    nDeclOfXDiffersFromPrevAtY);
end;

procedure TTestResolveGenerics.TestGen_ClassForward_Circle;
begin
  StartProgram(false);
  Add([
  '{$mode objfpc}',
  'type',
  '  TObject = class end;',
  '  generic TAnt<T> = class;',
  '  generic TFish<U> = class',
  '    private type AliasU = U;',
  '    var a: TAnt<AliasU>;',
  '        Size: AliasU;',
  '  end;',
  '  generic TAnt<T> = class',
  '    private type AliasT = T;',
  '    var f: TFish<AliasT>;',
  '        Speed: AliasT;',
  '  end;',
  'var',
  '  WordFish: specialize TFish<word>;',
  '  BoolAnt: specialize TAnt<boolean>;',
  '  w: word;',
  '  b: boolean;',
  'begin',
  '  WordFish.Size:=w;',
  '  WordFish.a.Speed:=w;',
  '  WordFish.a.f.Size:=w;',
  '  BoolAnt.Speed:=b;',
  '  BoolAnt.f.Size:=b;',
  '  BoolAnt.f.a.Speed:=b;',
  '']);
  ParseProgram;
end;

procedure TTestResolveGenerics.TestGen_Class_RedeclareInUnitImplFail;
begin
  StartUnit(false);
  Add([
  'interface',
  'type',
  '  TObject = class end;',
  '  generic TBird<T> = class v: T; end;',
  'implementation',
  'type generic TBird<T> = record v: T; end;',
  '']);
  CheckResolverException('Duplicate identifier "TBird" at afile.pp(5,16)',
    nDuplicateIdentifier);
end;

procedure TTestResolveGenerics.TestGen_Class_AnotherInUnitImpl;
begin
  StartUnit(false);
  Add([
  'interface',
  'type',
  '  TObject = class end;',
  '  generic TBird<T> = class v: T; end;',
  'implementation',
  'type generic TBird<T,U> = record x: T; y: U; end;',
  '']);
  ParseUnit;
end;

procedure TTestResolveGenerics.TestGen_Class_Method;
begin
  StartProgram(false);
  Add([
  '{$mode objfpc}',
  'type',
  '  TObject = class end;',
  '  {#Typ}T = word;',
  '  generic TBird<{#Templ}T> = class',
  '    function Fly(p:T): T; virtual; abstract;',
  '    function Run(p:T): T;',
  '  end;',
  'function TBird.Run(p:T): T;',
  'begin',
  'end;',
  'var',
  '  b: specialize TBird<word>;',
  '  {=Typ}w: T;',
  'begin',
  '  w:=b.Fly(w);',
  '  w:=b.Run(w);',
  '']);
  ParseProgram;
end;

procedure TTestResolveGenerics.TestGen_Class_MethodOverride;
begin
  StartProgram(false);
  Add([
  '{$mode objfpc}',
  'type',
  '  TObject = class end;',
  '  generic TBird<T> = class',
  '    function Fly(p:T): T; virtual; abstract;',
  '  end;',
  '  generic TEagle<S> = class(specialize TBird<S>)',
  '    function Fly(p:S): S; override;',
  '  end;',
  'function TEagle.Fly(p:S): S;',
  'begin',
  'end;',
  'var',
  '  e: specialize TEagle<word>;',
  '  w: word;',
  'begin',
  '  w:=e.Fly(w);',
  '']);
  ParseProgram;
end;

procedure TTestResolveGenerics.TestGen_Class_MethodDelphi;
begin
  StartProgram(false);
  Add([
  '{$mode delphi}',
  'type',
  '  TObject = class end;',
  '  {#Typ}T = word;',
  '  TBird<{#Templ}T> = class',
  '    function Fly(p:T): T; virtual; abstract;',
  '    function Run(p:T): T;',
  '  end;',
  'function TBird<T>.Run(p:T): T;',
  'begin',
  'end;',
  'var',
  '  b: TBird<word>;',
  '  {=Typ}w: T;',
  'begin',
  '  w:=b.Fly(w);',
  '  w:=b.Run(w);',
  '']);
  ParseProgram;
end;

procedure TTestResolveGenerics.TestGen_Class_MethodDelphiTypeParamMissing;
begin
  StartProgram(false);
  Add([
  '{$mode delphi}',
  'type',
  '  TObject = class end;',
  '  TBird<T> = class',
  '    function Run(p:T): T;',
  '  end;',
  'function TBird.Run(p:T): T;',
  'begin',
  'end;',
  'begin',
  '']);
  CheckResolverException('TBird<> expected, but TBird found',nXExpectedButYFound);
end;

procedure TTestResolveGenerics.TestGen_Class_MethodImplConstraintFail;
begin
  StartProgram(false);
  Add([
  '{$mode delphi}',
  'type',
  '  TObject = class end;',
  '  TBird<T: record> = class',
  '    function Run(p:T): T;',
  '  end;',
  'function TBird<T: record>.Run(p:T): T;',
  'begin',
  'end;',
  'begin',
  '']);
  CheckResolverException('T cannot have parameters',nXCannotHaveParameters);
end;

procedure TTestResolveGenerics.TestGen_Class_MethodImplTypeParamNameMismatch;
begin
  StartProgram(false);
  Add([
  '{$mode delphi}',
  'type',
  '  TObject = class end;',
  '  TBird<T> = class',
  '    procedure DoIt;',
  '  end;',
  'procedure TBird<S>.DoIt;',
  'begin',
  'end;',
  'begin',
  '']);
  CheckResolverException('T expected, but S found',nXExpectedButYFound);
end;

procedure TTestResolveGenerics.TestGen_Class_SpecializeSelfInside;
begin
  StartProgram(false);
  Add([
  '{$mode objfpc}',
  'type',
  '  TObject = class end;',
  '  generic TBird<T> = class',
  '    e: T;',
  '    v: TBird<boolean>;',
  '  end;',
  'var',
  '  b: specialize TBird<word>;',
  '  w: word;',
  'begin',
  '  b.e:=w;',
  '  if b.v.e then ;',
  '']);
  ParseProgram;
end;

procedure TTestResolveGenerics.TestGen_Class_GenAncestor;
begin
  StartProgram(false);
  Add([
  '{$mode objfpc}',
  'type',
  '  TObject = class end;',
  '  generic TBird<T> = class',
  '    i: T;',
  '  end;',
  '  generic TEagle<T> = class(TBird<T>)',
  '    j: T;',
  '  end;',
  'var',
  '  e: specialize TEagle<word>;',
  'begin',
  '  e.i:=e.j;',
  '']);
  ParseProgram;
end;

procedure TTestResolveGenerics.TestGen_Class_AncestorSelfFail;
begin
  StartProgram(false);
  Add([
  '{$mode objfpc}',
  'type',
  '  TObject = class end;',
  '  generic TBird<T> = class(TBird<word>)',
  '    e: T;',
  '  end;',
  'var',
  '  b: specialize TBird<word>;',
  'begin',
  '']);
  CheckResolverException('type "TBird<>" is not yet completely defined',nTypeXIsNotYetCompletelyDefined);
end;

procedure TTestResolveGenerics.TestGen_ClassOfSpecializeFail;
begin
  StartProgram(false);
  Add([
  '{$mode objfpc}',
  'type',
  '  TObject = class end;',
  '  generic TBird<T> = class',
  '    e: T;',
  '  end;',
  '  TBirdClass = class of specialize TBird<word>;',
  'begin',
  '']);
  CheckParserException('Expected "Identifier" at token "specialize" in file afile.pp at line 8 column 25',nParserExpectTokenError);
end;

procedure TTestResolveGenerics.TestGen_Class_NestedType;
begin
  StartProgram(false);
  Add([
  '{$mode objfpc}',
  'type',
  '  TObject = class end;',
  '  generic TBird<T> = class',
  '  public type',
  '    TArrayEvent = reference to procedure(El: T);',
  '  public',
  '    p: TArrayEvent;',
  '  end;',
  '  TBirdWord = specialize TBird<word>;',
  'var',
  '  b: TBirdWord;',
  'begin',
  '  b.p:=procedure(El: word) begin end;']);
  ParseProgram;
end;

procedure TTestResolveGenerics.TestGen_Class_NestedRecord;
begin
  StartProgram(false);
  Add([
  '{$mode objfpc}',
  '{$modeswitch advancedrecords}',
  'type',
  '  TObject = class end;',
  '  generic TBird<T> = class',
  '  public type TWing = record',
  '      s: T;',
  '      function GetIt: T;',
  '    end;',
  '  public',
  '    w: TWing;',
  '  end;',
  '  TBirdWord = specialize TBird<word>;',
  'function TBird.TWing.GetIt: T;',
  'begin',
  'end;',
  'var',
  '  b: TBirdWord;',
  '  i: word;',
  'begin',
  '  b.w.s:=i;',
  '  i:=b.w.GetIt;',
  '']);
  ParseProgram;
end;

procedure TTestResolveGenerics.TestGen_Class_NestedClass;
begin
  StartProgram(false);
  Add([
  '{$mode objfpc}',
  'type',
  '  TObject = class end;',
  '  generic TBird<T> = class',
  '  public type TWing = class',
  '      s: T;',
  '      function GetIt: T;',
  '    end;',
  '  public',
  '    w: TWing;',
  '  end;',
  '  TBirdWord = specialize TBird<word>;',
  'function TBird.TWing.GetIt: T;',
  'begin',
  'end;',
  'var',
  '  b: TBirdWord;',
  '  i: word;',
  'begin',
  '  b.w.s:=3;',
  '  i:=b.w.GetIt;',
  '']);
  ParseProgram;
end;

procedure TTestResolveGenerics.TestGen_Class_Enums_NotPropagating;
begin
  StartProgram(false);
  Add([
  '{$mode objfpc}',
  'type',
  '  TObject = class end;',
  '  generic TBird<T> = class',
  '  public type',
  '    TEnum = (red, blue);',
  '  const',
  '    e = blue;',
  '  end;',
  'const',
  '  r = red;',
  'begin']);
  CheckResolverException('identifier not found "red"',nIdentifierNotFound);
end;

procedure TTestResolveGenerics.TestGen_Class_Self;
begin
  StartProgram(false);
  Add([
  '{$mode objfpc}',
  'type',
  '  TObject = class',
  '  end;',
  '  generic TAnimal<T> = class end;',
  '  generic TBird<T> = class(TAnimal<T>)',
  '    function GetObj: TObject;',
  '    procedure Fly(Obj: TObject); virtual; abstract;',
  '  end;',
  '  TProc = procedure(Obj: TObject) of object;',
  '  TWordBird = specialize TBird<word>;',
  'function TBird.GetObj: TObject;',
  'var p: TProc;',
  'begin',
  '  Result:=Self;',
  '  if Self.GetObj=Result then ;',
  '  Fly(Self);',
  '  p:=@Fly;',
  '  p(Self);',
  'end;',
  'begin']);
  ParseProgram;
end;

procedure TTestResolveGenerics.TestGen_Class_MemberTypeConstructor;
begin
  StartProgram(false);
  Add([
  '{$mode delphi}',
  'type',
  '  TObject = class end;',
  '  TAnimal<A> = class',
  '  end;',
  '  TAnt<L> = class',
  '    constructor Create(A: TAnimal<L>);',
  '  end;',
  '  TBird<T> = class(TAnimal<T>)',
  '  type TMyAnt = TAnt<T>;',
  '    function Fly: TMyAnt;',
  '  end;',
  '  TWordBird = TBird<word>;',
  'constructor TAnt<L>.Create(A: TAnimal<L>);',
  'begin',
  'end;',
  'function TBird<T>.Fly: TMyAnt;',
  'begin',
  '  Result:=TMyAnt.Create(Self);',
  'end;',
  'begin']);
  ParseProgram;
end;

procedure TTestResolveGenerics.TestGen_Class_List;
begin
  StartProgram(false);
  Add([
  '{$mode objfpc}',
  'type',
  '  TObject = class end;',
  '  generic TList<T> = class',
  '  strict private',
  '    FItems: array of T;',
  '    function GetItems(Index: longint): T;',
  '    procedure SetItems(Index: longint; Value: T);',
  '  public',
  '    procedure Alter(w: T);',
  '    property Items[Index: longint]: T read GetItems write SetItems; default;',
  '  end;',
  '  TWordList = specialize TList<word>;',
  'function TList.GetItems(Index: longint): T;',
  'begin',
  '  Result:=FItems[Index];',
  'end;',
  'procedure TList.SetItems(Index: longint; Value: T);',
  'begin',
  '  FItems[Index]:=Value;',
  'end;',
  'procedure TList.Alter(w: T);',
  'begin',
  '  SetLength(FItems,length(FItems)+1);',
  '  Insert(w,FItems,2);',
  '  Delete(FItems,2,3);',
  'end;',
  'var l: TWordList;',
  '  w: word;',
  'begin',
  '  l[1]:=w;',
  '  w:=l[2];']);
  ParseProgram;
end;

procedure TTestResolveGenerics.TestGen_ExtClass_Array;
begin
  StartProgram(false);
  Add([
  '{$mode delphi}',
  '{$ModeSwitch externalclass}',
  'type',
  '  NativeInt = longint;',
  '  TJSGenArray<T> = Class external name ''Array''',
  '  private',
  '    function GetElements(Index: NativeInt): T; external name ''[]'';',
  '    procedure SetElements(Index: NativeInt; const AValue: T); external name ''[]'';',
  '  public',
  '    type TSelfType = TJSGenArray<T>;',
  '    TArrayEvent = reference to function(El: T; Arr: TSelfType): Boolean;',
  '    TArrayCallback = TArrayEvent;',
  '  public',
  '    FLength : NativeInt; external name ''length'';',
  '    constructor new; overload;',
  '    constructor new(aLength : NativeInt); overload;',
  '    class function _of() : TSelfType; varargs; external name ''of'';',
  '    function every(const aCallback: TArrayCallBack): boolean; overload;',
  '    function fill(aValue : T) : TSelfType; overload;',
  '    function fill(aValue : T; aStartIndex : NativeInt) : TSelfType; overload;',
  '    function fill(aValue : T; aStartIndex,aEndIndex : NativeInt) : TSelfType; overload;',
  '    property Length : NativeInt Read FLength Write FLength;',
  '    property Elements[Index: NativeInt]: T read GetElements write SetElements; default;',
  '  end;',
  '  TJSWordArray = TJSGenArray<word>;',
  'var',
  '  wa: TJSWordArray;',
  '  w: word;',
  'begin',
  '  wa:=TJSWordArray.new;',
  '  wa:=TJSWordArray.new(3);',
  '  wa:=TJSWordArray._of(4,5);',
  '  wa:=wa.fill(7);',
  '  wa:=wa.fill(7,8,9);',
  '  w:=wa.length;',
  '  wa.length:=10;',
  '  wa[11]:=w;',
  '  w:=wa[12];',
  '  wa.every(function(El: word; Arr: TJSWordArray): Boolean',
  '           begin',
  '           end',
  '      );',
  '']);
  ParseProgram;
end;

procedure TTestResolveGenerics.TestGen_ClassInterface;
begin
  StartProgram(false);
  Add([
  'type',
  '  {$interfaces corba}',
  '  generic ICorbaIntf<T> = interface',
  '    procedure Fly(a: T);',
  '  end;',
  '  {$interfaces com}',
  '  IUnknown = interface',
  '  end;',
  '  IInterface = IUnknown;',
  '  generic IComIntf<T> = interface',
  '    procedure Run(b: T);',
  '  end;',
  'begin']);
  ParseProgram;
end;

procedure TTestResolveGenerics.TestGen_ClassInterface_Method;
begin
  StartProgram(false);
  Add([
  'type',
  '  {$interfaces corba}',
  '  generic IBird<T> = interface',
  '    procedure Fly(a: T);',
  '  end;',
  '  TObject = class end;',
  '  generic TBird<U> = class(IBird<U>)',
  '    procedure Fly(a: U);',
  '  end;',
  'procedure TBird.Fly(a: U);',
  'begin',
  'end;',
  'var b: specialize IBird<word>;',
  'begin',
  '  b.Fly(3);']);
  ParseProgram;
end;

procedure TTestResolveGenerics.TestGen_DynArray;
begin
  StartProgram(false);
  Add([
  'type',
  '  generic TArray<T> = array of T;',
  '  TWordArray = specialize TArray<word>;',
  'var',
  '  a: specialize TArray<word>;',
  '  b: TWordArray;',
  '  w: word;',
  'begin',
  '  a[1]:=2;',
  '  b[2]:=a[3]+b[4];',
  '  a:=b;',
  '  b:=a;',
  '  SetLength(a,5);',
  '  SetLength(b,6);',
  '  w:=length(a)+low(a)+high(a);',
  '']);
  ParseProgram;
end;

procedure TTestResolveGenerics.TestGen_StaticArray;
begin
  StartProgram(false);
  Add([
  'type',
  '  generic TBird<T> = array[T] of word;',
  '  TByteBird = specialize TBird<byte>;',
  'var',
  '  a: specialize TBird<byte>;',
  '  b: TByteBird;',
  '  i: byte;',
  'begin',
  '  a[1]:=2;',
  '  b[2]:=a[3]+b[4];',
  '  a:=b;',
  '  b:=a;',
  '  i:=low(a);',
  '  i:=high(a);',
  '  for i in a do ;',
  '']);
  ParseProgram;
end;

procedure TTestResolveGenerics.TestGen_Array_Anoynmous;
begin
  StartProgram(false);
  Add([
  'type',
  '  generic TRec<T> = record',
  '    a: array of T;',
  '  end;',
  '  TWordRec = specialize TRec<word>;',
  'var',
  '  a: specialize TRec<word>;',
  '  b: TWordRec;',
  '  w: word;',
  'begin',
  '  a:=b;',
  '  a.a:=b.a;',
  '  a.a[1]:=2;',
  '  b.a[2]:=a.a[3]+b.a[4];',
  '  b:=a;',
  '  SetLength(a.a,5);',
  '  SetLength(b.a,6);',
  '  w:=length(a.a)+low(a.a)+high(a.a);',
  '']);
  ParseProgram;
end;

procedure TTestResolveGenerics.TestGen_ProcType;
begin
  StartProgram(false);
  Add([
  'type',
  '  generic TFunc<T> = function(v: T): T;',
  '  TWordFunc = specialize TFunc<word>;',
  'function GetIt(w: word): word;',
  'begin',
  'end;',
  'var',
  '  a: specialize TFunc<word>;',
  '  b: TWordFunc;',
  '  w: word;',
  'begin',
  '  a:=nil;',
  '  b:=nil;',
  '  a:=b;',
  '  b:=a;',
  '  w:=a(w);',
  '  w:=b(w);',
  '  a:=@GetIt;',
  '  b:=@GetIt;',
  '']);
  ParseProgram;
end;

procedure TTestResolveGenerics.TestGen_PointerDirectSpecializeFail;
begin
  StartProgram(false);
  Add([
  'type',
  '  generic TRec<T> = record v: T; end;',
  '  PRec = ^specialize TRec<word>;',
  'begin',
  '']);
  CheckParserException('Expected "Identifier" at token "specialize" in file afile.pp at line 4 column 11',nParserExpectTokenError);
end;

procedure TTestResolveGenerics.TestGen_GenericFunction;
begin
  exit;
  StartProgram(false);
  Add([
  'generic function DoIt<T>(a: T): T;',
  'var i: T;',
  'begin',
  '  a:=i;',
  '  Result:=a;',
  'end;',
  'var w: word;',
  'begin',
  //'  w:=DoIt<word>(3);',
  '']);
  ParseProgram;
end;

procedure TTestResolveGenerics.TestGen_LocalVar;
begin
  StartProgram(false);
  Add([
  '{$mode objfpc}',
  'type',
  '  TObject = class end;',
  '  generic TBird<{#Templ}T> = class',
  '    function Fly(p:T): T;',
  '  end;',
  'function TBird.Fly(p:T): T;',
  'var l: T;',
  'begin',
  '  l:=p;',
  '  p:=l;',
  '  Result:=p;',
  '  Result:=l;',
  '  l:=Result;',
  'end;',
  'var',
  '  b: specialize TBird<word>;',
  '  w: word;',
  'begin',
  '  w:=b.Fly(w);',
  '']);
  ParseProgram;
end;

procedure TTestResolveGenerics.TestGen_Statements;
begin
  StartProgram(false);
  Add([
  '{$mode objfpc}',
  'type',
  '  TObject = class end;',
  '  generic TBird<{#Templ}T> = class',
  '    function Fly(p:T): T;',
  '  end;',
  'function TBird.Fly(p:T): T;',
  'var',
  '  v1,v2,v3:T;',
  'begin',
  '  v1:=1;',
  '  v2:=v1+v1*v1+v1 div p;',
  '  v3:=-v1;',
  '  repeat',
  '    v1:=v1+1;',
  '  until v1>=5;',
  '  while v1>=0 do',
  '    v1:=v1-v2;',
  '  for v1:=v2 to v3 do v2:=v1;',
  '  if v1<v2 then v3:=v1 else v3:=v2;',
  '  if v1<v2 then else ;',
  '  case v1 of',
  '  1: v3:=3;',
  '  end;',
  'end;',
  'var',
  '  b: specialize TBird<word>;',
  'begin',
  '  b.Fly(2);',
  '']);
  ParseProgram;
end;

procedure TTestResolveGenerics.TestGen_InlineSpecializeExpr;
begin
  StartProgram(false);
  Add([
  '{$mode objfpc}',
  'type',
  '  TObject = class end;',
  '  generic TBird<T> = class',
  '    constructor Create;',
  '  end;',
  '  generic TAnt<U> = class',
  '    constructor Create;',
  '  end;',
  'constructor TBird.Create;',
  'var',
  '  a: TAnt<T>;',
  '  b: TAnt<word>;',
  'begin',
  '  a:=TAnt<T>.create;',
  '  b:=TAnt<word>.create;',
  'end;',
  'constructor TAnt.Create;',
  'var',
  '  i: TBird<U>;',
  '  j: TBird<word>;',
  '  k: TAnt<U>;',
  'begin',
  '  i:=TBird<U>.create;',
  '  j:=TBird<word>.create;',
  '  k:=TAnt<U>.create;',
  'end;',
  'var a: TAnt<word>;',
  'begin',
  '  a:=TAnt<word>.create;',
  '']);
  ParseProgram;
end;

procedure TTestResolveGenerics.TestGen_TryExcept;
begin
  StartProgram(false);
  Add([
  '{$mode objfpc}',
  'type',
  '  TObject = class end;',
  '  generic TBird<{#Templ}T> = class',
  '    function Fly(p:T): T;',
  '  end;',
  '  Exception = class',
  '  end;',
  '  generic EMsg<T> = class',
  '    Msg: T;',
  '  end;',
  'function TBird.Fly(p:T): T;',
  'var',
  '  v1,v2,v3:T;',
  'begin',
  '  try',
  '  finally',
  '  end;',
  '  try',
  '    v1:=v2;',
  '  finally',
  '    v2:=v1;',
  '  end;',
  '  try',
  '  except',
  '    on Exception do ;',
  '    on E: Exception do ;',
  '    on E: EMsg<boolean> do E.Msg:=true;',
  '    on E: EMsg<T> do E.Msg:=1;',
  '  end;',
  'end;',
  'var',
  '  b: specialize TBird<word>;',
  'begin',
  '  b.Fly(2);',
  '']);
  ParseProgram;
end;

initialization
  RegisterTests([TTestResolveGenerics]);

end.

