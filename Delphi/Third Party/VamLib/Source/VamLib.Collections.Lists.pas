unit VamLib.Collections.Lists;

interface


type
  // The 'Simple' list classes are lightweight list classes for use
  // where a full list class isn't required.
  // - Iteration via the Raw:TArray field is quick.
  // - Delete operations are slow.
  // - Insert operations are slow.
  // - Append operations are good.

  TSimpleList<T> = class;
  TSimpleObjectList<T : class> = class;

  TObjectList = class;



  TSimpleList<T> = class
  private
    fCount : integer;
    fCapacity : integer;
    procedure SetCount(const Value: integer);
    procedure SetCapacity(const Value: integer);
    function GetItem(Index: integer): T;  inline;

    procedure Grow; inline;
    procedure SetItem(Index: integer; const Value: T);
  public
    Raw : TArray<T>; //The raw, naked, array.

    destructor Destroy; override;

    function New:Pointer;

    function Append(const Value : T):integer;
    procedure Delete(const Index : integer);

    procedure Clear;

    property Count    : integer read fCount    write SetCount;
    property Capacity : integer read fCapacity write SetCapacity;

    property Items[Index:integer]:T read GetItem write SetItem; default;
  end;


  TSimpleObjectList<T : class> = class
  private
    fCount : integer;
    fCapacity : integer;
    fOwnsObjects: boolean;
    procedure SetCount(const Value: integer);
    procedure SetCapacity(const Value: integer);
    function GetItem(Index: integer): T;  inline;

    procedure Grow; inline;
    procedure SetItem(Index: integer; const Value: T);
  protected
    procedure FreeObjectAt(Index : integer);
  public
    Raw : TArray<T>; //The raw, naked, array.

    destructor Destroy; override;

    function Add(Item : T):integer;
    procedure Delete(const Index : integer);

    procedure Clear;

    property Count    : integer read fCount    write SetCount;
    property Capacity : integer read fCapacity write SetCapacity;

    property Items[Index:integer]:T read GetItem write SetItem; default;

    property OwnsObjects : boolean read fOwnsObjects write fOwnsObjects;
  end;

  TSimpleRecordList<T : record> = record
  private
    fCount : integer;
    fCapacity : integer;
    procedure SetCount(const Value: integer);
    procedure SetCapacity(const Value: integer);
    function GetItem(Index: integer): T;  inline;

    procedure Grow; inline;
    procedure SetItem(Index: integer; const Value: T);
  public
    Raw : TArray<T>; //The raw, naked, array.

    function New:Pointer;

    function Append(const Value : T):integer;
    procedure Delete(const Index : integer);

    procedure Clear;

    property Count    : integer read fCount    write SetCount;
    property Capacity : integer read fCapacity write SetCapacity;

    property Items[Index:integer]:T read GetItem write SetItem; default;
  end;


  TObjectList = class(TSimpleObjectList<TObject>)
  private
  public
  end;

implementation

uses
  SysUtils;

{ TSimpleList<T> }

destructor TSimpleList<T>.Destroy;
begin
  SetLength(Raw, 0);
  inherited;
end;

procedure TSimpleList<T>.Clear;
begin
  fCapacity := 0;
  fCount    := 0;
  SetLength(Raw, 0);
end;

function TSimpleList<T>.GetItem(Index: integer): T;
begin
  result := Raw[Index];
end;

procedure TSimpleList<T>.Grow;
begin
  SetLength(Raw, fCapacity + 10);
  inc(fCapacity, 10);
end;

function TSimpleList<T>.New: Pointer;
begin
  if (fCount) >= fCapacity then Grow;
  result := @Raw[fCount];
  inc(fCount);
end;

procedure TSimpleList<T>.SetCapacity(const Value: integer);
begin
  fCapacity := Value;
  SetLength(Raw, Value);
  if fCapacity < fCount then fCount := fCapacity;
end;

procedure TSimpleList<T>.SetCount(const Value: integer);
begin
  fCount := Value;
  if fCount > fCapacity then
  begin
    SetCapacity(Value);
  end;
end;

procedure TSimpleList<T>.SetItem(Index: integer; const Value: T);
begin
  Finalize(Raw[Index]);
  Move(Value, Raw[Index], SizeOf(T));
end;

function TSimpleList<T>.Append(const Value: T):integer;
begin
  if (fCount) >= fCapacity then Grow;

  // important: call finalize before moving the new value in to avoid memory
  // leaks.
  Finalize(Raw[fCount]);

  Move(Value, Raw[fCount], SizeOf(T));
  inc(fCount);
  result := fCount;
end;

procedure TSimpleList<T>.Delete(const Index: integer);
var
  DataSize   : integer;
  c1: Integer;
begin
  assert(Index >= 0);
  assert(Index < fCount);

  if Index = fCount-1 then
  begin
    dec(fCount);
  end else
  begin
    DataSize := SizeOf(T);

    for c1 := Index to fCount-2 do
    begin
      Finalize(Raw[c1]);
      Move(Raw[c1+1], Raw[c1], DataSize);
    end;

    dec(fCount);
  end;
end;




{ TSimpleObjectList<T> }

destructor TSimpleObjectList<T>.Destroy;
begin
  Clear;
  inherited;
end;


procedure TSimpleObjectList<T>.FreeObjectAt(Index: integer);
begin
  if assigned(Raw[Index]) then
  begin
    (Raw[Index] as TObject).Free;
    Raw[Index] := nil;
  end;
end;

procedure TSimpleObjectList<T>.Clear;
var
  c1: Integer;
begin
  if OwnsObjects then
  begin
    for c1 := 0 to fCount-1 do FreeObjectAt(c1);
  end;

  fCapacity := 0;
  fCount    := 0;
  SetLength(Raw, 0);
end;

function TSimpleObjectList<T>.GetItem(Index: integer): T;
begin
  result := Raw[Index];
end;

procedure TSimpleObjectList<T>.Grow;
begin
  SetLength(Raw, fCapacity + 10);
  inc(fCapacity, 10);
end;

procedure TSimpleObjectList<T>.SetCapacity(const Value: integer);
begin
  fCapacity := Value;
  SetLength(Raw, Value);
  if fCapacity < fCount then fCount := fCapacity;
end;

procedure TSimpleObjectList<T>.SetCount(const Value: integer);
begin
  fCount := Value;
  if fCount > fCapacity then
  begin
    SetCapacity(Value);
  end;
end;

procedure TSimpleObjectList<T>.SetItem(Index: integer; const Value: T);
begin
  Finalize(Raw[Index]);
  Move(Value, Raw[Index], SizeOf(T));
end;


function TSimpleObjectList<T>.Add(Item: T): integer;
begin
  if fCount = fCapacity then Grow;
  Raw[fCount] := Item;
  inc(fCount);
end;

procedure TSimpleObjectList<T>.Delete(const Index: integer);
var
  DataSize   : integer;
  c1: Integer;
begin
  assert(Index >= 0);
  assert(Index < fCount);

  if Index = fCount-1 then
  begin
    if OwnsObjects then FreeObjectAt(Index);
    dec(fCount);
  end else
  begin
    if OwnsObjects then FreeObjectAt(Index);

    DataSize := SizeOf(T);

    for c1 := Index to fCount-2 do
    begin
      Move(Raw[c1+1], Raw[c1], DataSize);
    end;

    dec(fCount);
  end;
end;


{ TRecordArray<T> }

procedure TSimpleRecordList<T>.Clear;
begin
  fCapacity := 0;
  fCount    := 0;
  SetLength(Raw, 0);
end;

function TSimpleRecordList<T>.GetItem(Index: integer): T;
begin
  result := Raw[Index];
end;

procedure TSimpleRecordList<T>.Grow;
begin
  SetLength(Raw, fCapacity + 10);
  inc(fCapacity, 10);
end;

function TSimpleRecordList<T>.New: Pointer;
begin
  if (fCount) >= fCapacity then Grow;
  result := @Raw[fCount];
  inc(fCount);
end;

procedure TSimpleRecordList<T>.SetCapacity(const Value: integer);
begin
  fCapacity := Value;
  SetLength(Raw, Value);
  if fCapacity < fCount then fCount := fCapacity;
end;

procedure TSimpleRecordList<T>.SetCount(const Value: integer);
begin
  fCount := Value;
  if fCount > fCapacity then
  begin
    SetCapacity(Value);
  end;
end;

procedure TSimpleRecordList<T>.SetItem(Index: integer; const Value: T);
begin
  Finalize(Raw[Index]);
  Move(Value, Raw[Index], SizeOf(T));
end;

function TSimpleRecordList<T>.Append(const Value: T):integer;
begin
  if (fCount) >= fCapacity then Grow;

  // important: call finalize before moving the new value in to avoid memory
  // leaks.
  Finalize(Raw[fCount]);

  Move(Value, Raw[fCount], SizeOf(T));
  inc(fCount);
  result := fCount;
end;

procedure TSimpleRecordList<T>.Delete(const Index: integer);
var
  DataSize   : integer;
  c1: Integer;
begin
  assert(Index >= 0);
  assert(Index < fCount);

  if Index = fCount-1 then
  begin
    dec(fCount);
  end else
  begin
    DataSize := SizeOf(T);

    for c1 := Index to fCount-2 do
    begin
      Finalize(Raw[c1]);
      Move(Raw[c1+1], Raw[c1], DataSize);
    end;

    dec(fCount);
  end;
end;





end.
