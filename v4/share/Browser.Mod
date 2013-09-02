MODULE Browser;	(* RC 29.10.93 *)	(* object model 4.12.93 *)

	IMPORT
		OPM := OfrontOPM, OPS := OfrontOPS, OPT := OfrontOPT, OPV := OfrontOPV,
		Texts, TextFrames, Oberon, MenuViewers;

	CONST
		OptionChar = "\";
		(* object modes *)
		Var = 1; VarPar = 2; Con = 3; Fld = 4; Typ = 5; LProc = 6; XProc = 7;
		SProc = 8; CProc = 9; IProc = 10; Mod = 11; Head = 12; TProc = 13;

		(* structure forms *)
		Undef = 0; Byte = 1; Bool = 2; Char = 3; SInt = 4; Int = 5; LInt = 6;
		Real = 7; LReal = 8; Set = 9; String = 10; NilTyp = 11; NoTyp = 12;
		Pointer = 13; ProcTyp = 14; Comp = 15;

		(* composite structure forms *)
		Basic = 1; Array = 2; DynArr = 3; Record = 4;

		(* module visibility of objects *)
		internal = 0; external = 1; externalR = 2;

		(* symbol file items *)
		Smname = 16; Send = 18; Stype = 19; Salias = 20; Svar = 21; Srvar = 22;
		Svalpar = 23; Svarpar = 24; Sfld = 25; Srfld = 26; Shdptr = 27; Shdpro = 28; Stpro = 29; Shdtpro = 30;
		Sxpro = 31; Sipro = 32; Scpro = 33; Sstruct = 34; Ssys = 35; Sptr = 36; Sarr = 37; Sdarr = 38; Srec = 39; Spro = 40;

		maxImps = 31;

	VAR
		W: Texts.Writer;
		option: CHAR;

	PROCEDURE Ws(s: ARRAY OF CHAR); BEGIN Texts.WriteString(W, s) END Ws;
	PROCEDURE Wch(ch: CHAR); BEGIN Texts.Write(W, ch) END Wch;
	PROCEDURE Wi(i: LONGINT); BEGIN Texts.WriteInt(W, i, 0) END Wi;
	PROCEDURE Wln; BEGIN Texts.WriteLn(W) END Wln;

	PROCEDURE Indent(i: INTEGER);
	BEGIN WHILE i > 0 DO Wch(" "); Wch(" "); DEC(i) END
	END Indent;

	PROCEDURE ^Wtype(typ: OPT.Struct);
	PROCEDURE ^Wstruct(typ: OPT.Struct);

	PROCEDURE Wsign(result: OPT.Struct; par: OPT.Object);
		VAR paren, res, first: BOOLEAN;
	BEGIN first := TRUE;
		res := (result # NIL) (* hidden mthd *) & (result # OPT.notyp);
		paren := res OR (par # NIL);
		IF paren THEN Ws(" (") END ;
		WHILE par # NIL DO
			IF ~first THEN Ws("; ") ELSE first := FALSE END ;
			IF option = "x" THEN Wi(par^.adr); Wch(" ") END ;
			IF par^.mode = VarPar THEN Ws("VAR ") END ;
			Ws(par^.name); Ws(": "); Wtype(par^.typ);
			par := par^.link
		END ;
		IF paren THEN Wch(")") END ;
		IF res THEN Ws(": "); Wtype(result) END
	END Wsign;

	PROCEDURE Objects(obj: OPT.Object; mode: SET);
		VAR i: LONGINT; m: INTEGER; s: SET; ext: OPT.ConstExt;
	BEGIN
		IF obj # NIL THEN
			Objects(obj^.left, mode);
			IF obj^.mode IN mode THEN
				CASE obj^.mode OF
				| Con:
						Indent(2); Ws(obj^.name); Ws(" = ");
						CASE obj^.typ^.form OF
						| Bool:
								IF obj^.conval^.intval = 1 THEN Ws("TRUE") ELSE Ws("FALSE") END
						| Char:
								IF (obj^.conval^.intval >= 32) & (obj^.conval^.intval <= 126) THEN 
									Wch(22X); Wch(CHR(obj^.conval^.intval)); Wch(22X)
								ELSE
									i := obj^.conval^.intval DIV 16;
									IF i > 9 THEN Wch(CHR(55 + i)) ELSE Wch(CHR(48 + i)) END ;
									i := obj^.conval^.intval MOD 16;
									IF i > 9 THEN Wch(CHR(55 + i)) ELSE Wch(CHR(48 + i)) END ;
									Wch("X")
								END
						| SInt, Int, LInt:
								Wi(obj^.conval^.intval)
						| Set:
								Wch("{"); i := 0; s := obj^.conval^.setval;
								WHILE i <= MAX(SET) DO
									IF i IN s THEN Wi(i); EXCL(s, i);
										IF s # {} THEN Ws(", ") END
									END ;
									INC(i)
								END ;
								Wch("}")
						| Real:
								Texts.WriteReal(W, SHORT(obj^.conval^.realval), 16)
						| LReal:
								Texts.WriteLongReal(W, obj^.conval^.realval, 23)
						| String:
								Ws(obj^.conval^.ext^)
						| NilTyp:
								Ws("NIL")
						END ;
						Wch(";"); Wln
				| Typ:
						IF obj^.name # "" THEN Indent(2);
							IF obj^.typ^.strobj = obj THEN	(* canonical name *)
								Wtype(obj^.typ); Ws(" = "); Wstruct(obj^.typ)
							ELSE	(* alias *)
								Ws(obj^.name); Ws(" = "); Wtype(obj^.typ)
							END ;
							Wch(";"); Wln
						END
				| Var:
						Indent(2); Ws(obj^.name);
						IF obj^.vis = externalR THEN Ws("-: ") ELSE Ws(": ") END ;
						Wtype(obj^.typ); Wch(";"); Wln
				| XProc, CProc, IProc:
						Indent(1); Ws("PROCEDURE ");
						IF obj^.mode = IProc THEN Wch("+")
						ELSIF obj^.mode = CProc THEN Wch("-")
						END ;
						Ws(obj^.name);
						Wsign(obj^.typ, obj^.link);
						IF obj^.mode = CProc THEN
							ext := obj^.conval^.ext; m := ORD(ext^[0]); i := 1; Ws('  "');
							WHILE i <= m DO Wch(ext^[i]); INC(i) END ;
							Wch('"');
						END ;
						Wch(";"); Wln
				END
			END ;
			Objects(obj^.right, mode)
		END
	END Objects;

	PROCEDURE Wmthd(obj: OPT.Object);
		VAR
	BEGIN
		IF obj # NIL THEN
			Wmthd(obj^.left);
			IF (obj^.mode = TProc) & ((obj^.name # OPM.HdTProcName) OR (option = "x")) THEN
				Indent(3); Ws("PROCEDURE (");
				IF obj^.name # OPM.HdTProcName THEN
					IF obj^.link^.mode = VarPar THEN Ws("VAR ") END ;
					Ws(obj^.link^.name); Ws(": "); Wtype(obj^.link^.typ)
				END ;
				Ws(") "); Ws(obj^.name);
				Wsign(obj^.typ, obj^.link^.link);
				Wch(";");
				IF option = "x" THEN Indent(1);
					Ws("(* methno: "); Wi(obj^.adr DIV 10000H);  Ws(" *)")
				END ;
				Wln;
			END ;
			Wmthd(obj^.right)
		END
	END Wmthd;

	PROCEDURE Wstruct(typ: OPT.Struct);
		VAR fld: OPT.Object;

		PROCEDURE SysFlag;
		BEGIN
			IF typ^.sysflag # 0 THEN
				Wch("["); Wi(typ^.sysflag); Ws("] ")
			END
		END SysFlag;

	BEGIN
		CASE typ^.form OF
		| Undef:
				Ws("Undef")
		| Pointer:
				Ws("POINTER "); SysFlag; Ws("TO "); Wtype(typ^.BaseTyp)
		| ProcTyp:
				Ws("PROCEDURE "); SysFlag; Wsign(typ^.BaseTyp, typ^.link)
		| Comp:
				CASE typ^.comp OF
				| Array:
						Ws("ARRAY "); SysFlag; Wi(typ^.n); Ws(" OF "); Wtype(typ^.BaseTyp)
				| DynArr:
						Ws("ARRAY "); SysFlag; Ws("OF "); Wtype(typ^.BaseTyp)
				| Record:
						Ws("RECORD ");SysFlag;
						IF typ^.BaseTyp # NIL THEN Wch("("); Wtype(typ^.BaseTyp); Wch(")") END ;
						Wln; fld := typ^.link;
						WHILE (fld # NIL) & (fld^.mode = Fld) DO
							IF (option = "x") OR (fld^.name[0] # "@") THEN Indent(3);
								IF option = "x" THEN Wi(fld^.adr); Wch(" ") END ;
								Ws(fld^.name);
								IF fld^.vis = externalR THEN Wch("-") END ;
								Ws(": "); Wtype(fld^.typ); Wch(";");
								Wln
							END ;
							fld := fld^.link
						END ;
						Wmthd(typ^.link);
						Indent(2); Ws("END ");
						IF option = "x" THEN Indent(1);
							Ws("(* size: "); Wi(typ^.size); Ws(" align: "); Wi(typ^.align);
							Ws(" nofm: "); Wi(typ^.n); Ws(" *)")
						END
				END
		END
	END Wstruct;

	PROCEDURE Wtype(typ: OPT.Struct);
		VAR obj: OPT.Object;
	BEGIN
		obj := typ^.strobj;
		IF obj^.name # "" THEN
			IF typ^.mno # 0 THEN Ws(OPT.GlbMod[typ^.mno].name); Wch(".")
			ELSIF (typ = OPT.bytetyp) OR (typ = OPT.sysptrtyp) THEN Ws("SYSTEM.")
			ELSIF obj^.vis = internal THEN Wch("#")
			END ;
			Ws(obj^.name)
		ELSE
			IF (option = "x") & (typ^.ref > OPM.MaxStruct) THEN Wch("#"); Wi(typ^.ref - OPM.MaxStruct); Wch(" ") END ;
			Wstruct(typ)
		END
	END Wtype;

	PROCEDURE WModule(name: OPS.Name; T: Texts.Text);
		VAR i: INTEGER;
			beg, end: LONGINT; first, done: BOOLEAN;

		PROCEDURE Header(s: ARRAY OF CHAR);
		BEGIN
			beg := W.buf.len; Indent(1); Ws(s); Wln; end := W.buf.len
		END Header;

		PROCEDURE CheckHeader;
		 	VAR len: LONGINT;
		BEGIN
			len := T.len;
			IF end = W.buf.len THEN Texts.Append(T, W.buf); Texts.Delete(T, len+beg, len+end)
			ELSE Wln
			END
		END CheckHeader;
				
	BEGIN
		OPT.Import("@notself", name, done);
		IF done THEN
			Ws("DEFINITION "); Ws(name); Wch(";"); Wln; Wln;
			Header("IMPORT"); i := 1; first := TRUE;
			WHILE i < OPT.nofGmod DO
				IF first THEN first := FALSE; Indent(2) ELSE Ws(", ") END ;
				Ws(OPT.GlbMod[i].name);
				INC(i)
			END ;
			IF ~first THEN Wch(";"); Wln END ;
			CheckHeader;
			Header("CONST"); Objects(OPT.GlbMod[0].right, {Con}); CheckHeader;
			Header("TYPE"); Objects(OPT.GlbMod[0].right, {Typ}); CheckHeader;
			Header("VAR"); Objects(OPT.GlbMod[0].right, {Var}); CheckHeader;
			Objects(OPT.GlbMod[0].right, {XProc, IProc, CProc});
			Wln;
			Ws("END "); Ws(name); Wch("."); Wln; Texts.Append(T, W.buf)
		ELSE
			Texts.WriteString(W, name); Texts.WriteString(W, " -- symbol file not found");
			Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
		END
	END WModule;

	PROCEDURE GetArgs(VAR S: Texts.Scanner);
		VAR text: Texts.Text; beg, end, time: LONGINT;
	BEGIN
		Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
		IF (S.line#0) OR (S.class#Texts.Name) THEN
			Oberon.GetSelection(text, beg, end, time);
			IF time>=0 THEN Texts.OpenScanner(S, text, beg); Texts.Scan(S) END
		END
	END GetArgs;
	
	PROCEDURE Option(VAR S: Texts.Scanner);
	BEGIN option := 0X;
		Texts.Scan(S);
		IF (S.class=Texts.Char) & (S.c=OptionChar) THEN Texts.Scan(S);
			IF S.class=Texts.Name THEN option := S.s[0]; Texts.Scan(S) END
		END
	END Option;
	
	PROCEDURE Ident(VAR name, first: ARRAY OF CHAR);
		VAR i, j: INTEGER; ch: CHAR;
	BEGIN i := 0;
		WHILE name[i] # 0X DO INC(i) END ;
		WHILE (i >= 0) & (name[i] # "/") DO DEC(i) END ;
		INC(i); j := 0; ch := name[i];
		WHILE (ch # ".") & (ch # 0X) DO first[j] := ch; INC(i); INC(j); ch := name[i] END ;
		first[j] := 0X
	END Ident;
	
	PROCEDURE Append(VAR d: ARRAY OF CHAR; s: ARRAY OF CHAR);
		VAR i, j: INTEGER; ch: CHAR;
	BEGIN
		i := 0; WHILE d[i] # 0X DO INC(i) END ;
		j := 0; REPEAT ch := s[j]; d[i] := ch; INC(i); INC(j) UNTIL ch = 0X
	END Append;

	PROCEDURE ShowDef*;
		VAR S: Texts.Scanner; dummyR: Texts.Reader;
			T, dummyT: Texts.Text; vname, name: OPS.Name;
			mV: MenuViewers.Viewer; x, y: INTEGER;
	BEGIN
		GetArgs(S);
		IF S.class = Texts.Name THEN
			Ident(S.s, name); COPY(name, vname); Option(S);
			Append(vname, ".Def"); T := TextFrames.Text("");
			Oberon.AllocateUserViewer(Oberon.Mouse.X, x, y);
			mV := MenuViewers.New(
				TextFrames.NewMenu(vname, "System.Close  System.Copy  System.Grow  Edit.Search Edit.Store"),
				TextFrames.NewText(T, 0),
				TextFrames.menuH, x, y);
			NEW(dummyT); Texts.Open(dummyT, ""); Texts.OpenReader(dummyR, dummyT, 0);
			OPT.Init(name, {}); OPT.SelfName := "AvoidErr154"; WModule(name, T); OPT.Close
		END
	END ShowDef;

BEGIN
	OPT.typSize := OPV.TypSize;
	Texts.OpenWriter(W)
END Browser.
