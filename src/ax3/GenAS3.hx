package ax3;

import ax3.ParseTree;
import ax3.TypedTree;

@:nullSafety
class GenAS3 extends PrinterBase {
	public static function debugExpr(e:TExpr):String {
		var g = new GenAS3();
		g.printExpr(e);
		return g.toString();
	}

	public function writeModule(m:TModule) {
		printPackage(m.pack);
		for (d in m.privateDecls) {
			printDecl(d);
		}
		printTrivia(m.eof.leadTrivia);
	}

	function printPackage(p:TPackageDecl) {
		printTextWithTrivia("package", p.syntax.keyword);
		if (p.syntax.name != null) printDotPath(p.syntax.name);
		printOpenBrace(p.syntax.openBrace);
		for (i in p.imports) {
			printImport(i);
		}
		for (n in p.namespaceUses) {
			printUseNamespace(n.n);
			printSemicolon(n.semicolon);
		}
		printDecl(p.decl);
		printCloseBrace(p.syntax.closeBrace);
	}

	function printImport(i:TImport) {
		if (i.syntax.condCompBegin != null) printCondCompBegin(i.syntax.condCompBegin);
		printTextWithTrivia("import", i.syntax.keyword);
		printDotPath(i.syntax.path);
		switch i.kind {
			case TIDecl(_):
			case TIAliased(_): throw "assert";
			case TIAll(_, dot, asterisk):
				printDot(dot);
				printTextWithTrivia("*", asterisk);
		}
		printSemicolon(i.syntax.semicolon);
		if (i.syntax.condCompEnd != null) printCompCondEnd(i.syntax.condCompEnd);
	}

	function printDecl(d:TDecl) {
		switch d.kind {
			case TDClassOrInterface(c = {kind: TClass(info)}): printClassDecl(c, info);
			case TDClassOrInterface(i = {kind: TInterface(info)}): printInterfaceDecl(i, info);
			case TDVar(v): printModuleVarDecl(v);
			case TDFunction(f): printFunctionDecl(f);
			case TDNamespace(n): printNamespace(n);
		}
	}

	function printNamespace(ns:NamespaceDecl) {
		printDeclModifiers(ns.modifiers);
		printTextWithTrivia("namespace", ns.keyword);
		printTextWithTrivia(ns.name.text, ns.name);
		printSemicolon(ns.semicolon);
	}

	function printFunctionDecl(f:TFunctionDecl) {
		printMetadata(f.metadata);
		printDeclModifiers(f.modifiers);
		printTextWithTrivia("function", f.syntax.keyword);
		printTextWithTrivia(f.name, f.syntax.name);
		printSignature(f.fun.sig);
		printExpr(f.fun.expr);
	}

	function printModuleVarDecl(v:TModuleVarDecl) {
		printMetadata(v.metadata);
		printDeclModifiers(v.modifiers);
		printVarField(v);
	}

	function printInterfaceDecl(i:TClassOrInterfaceDecl, info:TInterfaceDeclInfo) {
		printMetadata(i.metadata);
		printDeclModifiers(i.modifiers);
		printTextWithTrivia("interface", i.syntax.keyword);
		printTextWithTrivia(i.name, i.syntax.name);
		if (info.extend != null) {
			printTextWithTrivia("extends", info.extend.keyword);
			for (i in info.extend.interfaces) {
				printDotPath(i.iface.syntax);
				if (i.comma != null) printComma(i.comma);
			}
		}
		printOpenBrace(i.syntax.openBrace);
		for (m in i.members) {
			switch (m) {
				case TMField(f): printInterfaceField(f);
				case TMCondCompBegin(b): printCondCompBegin(b);
				case TMCondCompEnd(b): printCompCondEnd(b);
				case TMStaticInit(_) | TMUseNamespace(_):
					throw "assert";
			}
		}
		printCloseBrace(i.syntax.closeBrace);
	}

	function printInterfaceField(f:TClassField) {
		printMetadata(f.metadata);

		switch (f.kind) {
			case TFFun(f):
				printTextWithTrivia("function", f.syntax.keyword);
				printTextWithTrivia(f.name, f.syntax.name);
				printSignature(f.fun.sig);
				printSemicolon(f.semicolon.sure());
			case TFGetter(f):
				printTextWithTrivia("function", f.syntax.functionKeyword);
				printTextWithTrivia("get", f.syntax.accessorKeyword);
				printTextWithTrivia(f.name, f.syntax.name);
				printSignature(f.fun.sig);
				printSemicolon(f.semicolon.sure());
			case TFSetter(f):
				printTextWithTrivia("function", f.syntax.functionKeyword);
				printTextWithTrivia("set", f.syntax.accessorKeyword);
				printTextWithTrivia(f.name, f.syntax.name);
				printSignature(f.fun.sig);
				printSemicolon(f.semicolon.sure());
			case TFVar(_): throw "assert";
		}
	}

	function printClassDecl(c:TClassOrInterfaceDecl, info:TClassDeclInfo) {
		printMetadata(c.metadata);
		printDeclModifiers(c.modifiers);
		printTextWithTrivia("class", c.syntax.keyword);
		printTextWithTrivia(c.name, c.syntax.name);
		if (info.extend != null) {
			printTextWithTrivia("extends", info.extend.syntax.keyword);
			printDotPath(info.extend.syntax.path);
		}
		if (info.implement != null) {
			printTextWithTrivia("implements", info.implement.keyword);
			for (i in info.implement.interfaces) {
				printDotPath(i.iface.syntax);
				if (i.comma != null) printComma(i.comma);
			}
		}
		printOpenBrace(c.syntax.openBrace);
		for (m in c.members) {
			switch (m) {
				case TMCondCompBegin(b): printCondCompBegin(b);
				case TMCondCompEnd(b): printCompCondEnd(b);
				case TMField(f): printClassField(f);
				case TMUseNamespace(n, semicolon): printUseNamespace(n); printSemicolon(semicolon);
				case TMStaticInit(i): printExpr(i.expr);
			}
		}
		printCloseBrace(c.syntax.closeBrace);
	}

	function printCondCompBegin(e:TCondCompBegin) {
		printCondCompVar(e.v);
		printOpenBrace(e.openBrace);
	}

	function printCompCondEnd(e:TCondCompEnd) {
		printCloseBrace(e.closeBrace);
	}

	function printDeclModifiers(modifiers:Array<DeclModifier>) {
		for (m in modifiers) {
			switch (m) {
				case DMPublic(t): printTextWithTrivia("public", t);
				case DMInternal(t): printTextWithTrivia("internal", t);
				case DMFinal(t): printTextWithTrivia("final", t);
				case DMDynamic(t): printTextWithTrivia("dynamic", t);
			}
		}
	}

	function printClassField(f:TClassField) {
		printMetadata(f.metadata);

		if (f.namespace != null) printTextWithTrivia(f.namespace.text, f.namespace);

		for (m in f.modifiers) {
			switch (m) {
				case FMPublic(t): printTextWithTrivia("public", t);
				case FMPrivate(t): printTextWithTrivia("private", t);
				case FMProtected(t): printTextWithTrivia("protected", t);
				case FMInternal(t): printTextWithTrivia("internal", t);
				case FMOverride(t): printTextWithTrivia("override", t);
				case FMStatic(t): printTextWithTrivia("static", t);
				case FMFinal(t): printTextWithTrivia("final", t);
			}
		}

		switch (f.kind) {
			case TFVar(v):
				printVarField(v);
			case TFFun(f):
				printTextWithTrivia("function", f.syntax.keyword);
				printTextWithTrivia(f.name, f.syntax.name);
				printSignature(f.fun.sig);
				printExpr(f.fun.expr);
			case TFGetter(f):
				printTextWithTrivia("function", f.syntax.functionKeyword);
				printTextWithTrivia("get", f.syntax.accessorKeyword);
				printTextWithTrivia(f.name, f.syntax.name);
				printSignature(f.fun.sig);
				printExpr(f.fun.expr);
			case TFSetter(f):
				printTextWithTrivia("function", f.syntax.functionKeyword);
				printTextWithTrivia("set", f.syntax.accessorKeyword);
				printTextWithTrivia(f.name, f.syntax.name);
				printSignature(f.fun.sig);
				printExpr(f.fun.expr);
		}
	}

	function printVarField(v:TVarField) {
		printVarKind(v.kind);
		for (v in v.vars) {
			printTextWithTrivia(v.name, v.syntax.name);
			if (v.syntax.type != null) {
				printSyntaxTypeHint(v.syntax.type);
			}
			if (v.init != null) printVarInit(v.init);
			if (v.comma != null) printComma(v.comma);
		}
		printSemicolon(v.semicolon);
	}

	function printMetadata(m:Array<Metadata>) {
		if (m.length == 0) return;
		var p = new Printer();
		p.printMetadata(m);
		buf.add(p.toString());
	}

	function printSignature(sig:TFunctionSignature) {
		printOpenParen(sig.syntax.openParen);
		for (arg in sig.args) {
			switch (arg.kind) {
				case TArgNormal(hint, init):
					printTextWithTrivia(arg.name, arg.syntax.name);
					if (hint != null) printSyntaxTypeHint(hint);
					if (init != null) printVarInit(init);

				case TArgRest(dots, _):
					printTextWithTrivia("...", dots);
					printTextWithTrivia(arg.name, arg.syntax.name);
			}
			if (arg.comma != null) printComma(arg.comma);
		}
		printCloseParen(sig.syntax.closeParen);
		printTypeHint(sig.ret);
	}

	function printTypeHint(hint:TTypeHint) {
		if (hint.syntax != null) {
			printSyntaxTypeHint(hint.syntax);
		}
	}

	function printSyntaxTypeHint(t:TypeHint) {
		printColon(t.colon);
		printSyntaxType(t.type);
	}

	function printExpr(e:TExpr) {
		switch (e.kind) {
			case TEParens(openParen, e, closeParen): printOpenParen(openParen); printExpr(e); printCloseParen(closeParen);
			case TECast(c): printCast(c);
			case TELocalFunction(f): printLocalFunction(f);
			case TELiteral(l): printLiteral(l);
			case TELocal(syntax, v): printTextWithTrivia(syntax.text, syntax);
			case TEField(object, fieldName, fieldToken): printFieldAccess(object, fieldName, fieldToken);
			case TEBuiltin(syntax, name): printTextWithTrivia(syntax.text, syntax);
			case TEDeclRef(dotPath, c): printDotPath(dotPath);
			case TECall(eobj, args): printExpr(eobj); printCallArgs(args);
			case TEArrayDecl(d): printArrayDecl(d);
			case TEVectorDecl(v): printVectorDecl(v);
			case TEReturn(keyword, e): printTextWithTrivia("return", keyword); if (e != null) printExpr(e);
			case TEThrow(keyword, e): printTextWithTrivia("throw", keyword); printExpr(e);
			case TEDelete(keyword, e): printTextWithTrivia("delete", keyword); printExpr(e);
			case TEBreak(keyword): printTextWithTrivia("break", keyword);
			case TEContinue(keyword): printTextWithTrivia("continue", keyword);
			case TEVars(kind, vars): printVars(kind, vars);
			case TEObjectDecl(o): printObjectDecl(o);
			case TEArrayAccess(a): printArrayAccess(a);
			case TEBlock(block): printBlock(block);
			case TETry(t): printTry(t);
			case TEVector(syntax, type): printVectorSyntax(syntax);
			case TETernary(t): printTernary(t);
			case TEIf(i): printIf(i);
			case TEWhile(w): printWhile(w);
			case TEDoWhile(w): printDoWhile(w);
			case TEFor(f): printFor(f);
			case TEForIn(f): printForIn(f);
			case TEForEach(f): printForEach(f);
			case TEHaxeFor(_) | TEHaxeRetype(_): throw "assert";
			case TEBinop(a, op, b): printBinop(a, op, b);
			case TEPreUnop(op, e): printPreUnop(op, e);
			case TEPostUnop(e, op): printPostUnop(e, op);
			case TEAs(e, keyword, type): printExpr(e); printTextWithTrivia("as", keyword); printSyntaxType(type.syntax);
			case TESwitch(s): printSwitch(s);
			case TENew(keyword, eclass, args): printNew(keyword, eclass, args);
			case TECondCompValue(v): printCondCompVar(v);
			case TECondCompBlock(v, expr): printCondCompVar(v); printExpr(expr);
			case TEXmlChild(x): printXmlChild(x);
			case TEXmlAttr(x): printXmlAttr(x);
			case TEXmlAttrExpr(x): printXmlAttrExpr(x);
			case TEXmlDescend(x): printXmlDescend(x);
			case TEUseNamespace(ns): printUseNamespace(ns);
		}
	}

	function printCast(c:TCast) {
		printDotPath(c.syntax.path);
		printOpenParen(c.syntax.openParen);
		printExpr(c.expr);
		printCloseParen(c.syntax.closeParen);
	}

	function printLocalFunction(f:TLocalFunction) {
		printTextWithTrivia("function", f.syntax.keyword);
		if (f.name != null) printTextWithTrivia(f.name.name, f.name.syntax);
		printSignature(f.fun.sig);
		printExpr(f.fun.expr);
	}

	function printXmlDescend(x:TXmlDescend) {
		printExpr(x.eobj);
		printTextWithTrivia("..", x.syntax.dotDot);
		printTextWithTrivia(x.name, x.syntax.name);
	}

	function printXmlChild(x:TXmlChild) {
		printExpr(x.eobj);
		printDot(x.syntax.dot);
		printTextWithTrivia(x.name, x.syntax.name);
	}

	function printXmlAttr(x:TXmlAttr) {
		printExpr(x.eobj);
		printDot(x.syntax.dot);
		printTextWithTrivia("@", x.syntax.at);
		printTextWithTrivia(x.name, x.syntax.name);
	}

	function printXmlAttrExpr(x:TXmlAttrExpr) {
		printExpr(x.eobj);
		printDot(x.syntax.dot);
		printTextWithTrivia("@", x.syntax.at);
		printOpenBracket(x.syntax.openBracket);
		printExpr(x.eattr);
		printCloseBracket(x.syntax.closeBracket);
	}

	function printSwitch(s:TSwitch) {
		printTextWithTrivia("switch", s.syntax.keyword);
		printOpenParen(s.syntax.openParen);
		printExpr(s.subj);
		printCloseParen(s.syntax.closeParen);
		printOpenBrace(s.syntax.openBrace);
		for (c in s.cases) {
			printTextWithTrivia("case", c.syntax.keyword);
			for (v in c.values) {
				printExpr(v);
				printColon(c.syntax.colon);
			}
			for (e in c.body) {
				printBlockExpr(e);
			}
		}
		if (s.def != null) {
			printTextWithTrivia("default", s.def.syntax.keyword);
			printColon(s.def.syntax.colon);
			for (e in s.def.body) {
				printBlockExpr(e);
			}
		}
		printCloseBrace(s.syntax.closeBrace);
	}

	function printVectorSyntax(syntax:VectorSyntax) {
		printTextWithTrivia("Vector", syntax.name);
		printDot(syntax.dot);
		printTypeParam(syntax.t);
	}

	function printTypeParam(t:TypeParam) {
		printTextWithTrivia("<", t.lt);
		printSyntaxType(t.type);
		printTextWithTrivia(">", t.gt);
	}

	function printSyntaxType(t:SyntaxType) {
		switch (t) {
			case TAny(star): printTextWithTrivia("*", star);
			case TPath(path): printDotPath(path);
			case TVector(v): printVectorSyntax(v);
		}
	}

	function printCondCompVar(v:TCondCompVar) {
		printTextWithTrivia(v.ns, v.syntax.ns);
		printTextWithTrivia("::", v.syntax.sep);
		printTextWithTrivia(v.name, v.syntax.name);
	}

	function printUseNamespace(ns:UseNamespace) {
		printTextWithTrivia("use", ns.useKeyword);
		printTextWithTrivia("namespace", ns.namespaceKeyword);
		printTextWithTrivia(ns.name.text, ns.name);
	}

	function printTry(t:TTry) {
		printTextWithTrivia("try", t.keyword);
		printExpr(t.expr);
		for (c in t.catches) {
			printTextWithTrivia("catch", c.syntax.keyword);
			printOpenParen(c.syntax.openParen);
			printTextWithTrivia(c.v.name, c.syntax.name);
			printColon(c.syntax.type.colon);
			printSyntaxType(c.syntax.type.type);
			printCloseParen(c.syntax.closeParen);
			printExpr(c.expr);
		}
	}

	function printWhile(w:TWhile) {
		printTextWithTrivia("while", w.syntax.keyword);
		printOpenParen(w.syntax.openParen);
		printExpr(w.cond);
		printCloseParen(w.syntax.closeParen);
		printExpr(w.body);
	}

	function printDoWhile(w:TDoWhile) {
		printTextWithTrivia("do", w.syntax.doKeyword);
		printExpr(w.body);
		printTextWithTrivia("while", w.syntax.whileKeyword);
		printOpenParen(w.syntax.openParen);
		printExpr(w.cond);
		printCloseParen(w.syntax.closeParen);
	}

	function printFor(f:TFor) {
		printTextWithTrivia("for", f.syntax.keyword);
		printOpenParen(f.syntax.openParen);
		if (f.einit != null) printExpr(f.einit);
		printSemicolon(f.syntax.initSep);
		if (f.econd != null) printExpr(f.econd);
		printSemicolon(f.syntax.condSep);
		if (f.eincr != null) printExpr(f.eincr);
		printCloseParen(f.syntax.closeParen);
		printExpr(f.body);
	}

	function printForIn(f:TForIn) {
		printTextWithTrivia("for", f.syntax.forKeyword);
		printOpenParen(f.syntax.openParen);
		printForInIter(f.iter);
		printCloseParen(f.syntax.closeParen);
		printExpr(f.body);
	}

	function printForEach(f:TForEach) {
		printTextWithTrivia("for", f.syntax.forKeyword);
		printTextWithTrivia("each", f.syntax.eachKeyword);
		printOpenParen(f.syntax.openParen);
		printForInIter(f.iter);
		printCloseParen(f.syntax.closeParen);
		printExpr(f.body);
	}

	function printForInIter(i:TForInIter) {
		printExpr(i.eit);
		printTextWithTrivia("in", i.inKeyword);
		printExpr(i.eobj);
	}

	function printNew(keyword:Token, eclass:TExpr, args:Null<TCallArgs>) {
		printTextWithTrivia("new", keyword);
		printExpr(eclass);
		if (args != null) printCallArgs(args);
	}

	function printVectorDecl(d:TVectorDecl) {
		printTextWithTrivia("new", d.syntax.newKeyword);
		printTypeParam(d.syntax.typeParam);
		printArrayDecl(d.elements);
	}

	function printArrayDecl(d:TArrayDecl) {
		printOpenBracket(d.syntax.openBracket);
		for (e in d.elements) {
			printExpr(e.expr);
			if (e.comma != null) printComma(e.comma);
		}
		printCloseBracket(d.syntax.closeBracket);
	}

	function printCallArgs(args:TCallArgs) {
		printOpenParen(args.openParen);
		for (a in args.args) {
			printExpr(a.expr);
			if (a.comma != null) printComma(a.comma);
		}
		printCloseParen(args.closeParen);
	}

	function printTernary(t:TTernary) {
		printExpr(t.econd);
		printTextWithTrivia("?", t.syntax.question);
		printExpr(t.ethen);
		printColon(t.syntax.colon);
		printExpr(t.eelse);
	}

	function printIf(i:TIf) {
		printTextWithTrivia("if", i.syntax.keyword);
		printOpenParen(i.syntax.openParen);
		printExpr(i.econd);
		printCloseParen(i.syntax.closeParen);
		printExpr(i.ethen);
		if (i.eelse != null) {
			printTextWithTrivia("else", i.eelse.keyword);
			printExpr(i.eelse.expr);
		}
	}

	function printPreUnop(op:PreUnop, e:TExpr) {
		switch (op) {
			case PreNot(t): printTextWithTrivia("!", t);
			case PreNeg(t): printTextWithTrivia("-", t);
			case PreIncr(t): printTextWithTrivia("++", t);
			case PreDecr(t): printTextWithTrivia("--", t);
			case PreBitNeg(t): printTextWithTrivia("~", t);
		}
		printExpr(e);
	}

	function printPostUnop(e:TExpr, op:PostUnop) {
		printExpr(e);
		switch (op) {
			case PostIncr(t): printTextWithTrivia("++", t);
			case PostDecr(t): printTextWithTrivia("--", t);
		}
	}

	function printBinop(a:TExpr, op:Binop, b:TExpr) {
		printExpr(a);
		switch (op) {
			case OpAdd(t): printTextWithTrivia("+", t);
			case OpSub(t): printTextWithTrivia("-", t);
			case OpDiv(t): printTextWithTrivia("/", t);
			case OpMul(t): printTextWithTrivia("*", t);
			case OpMod(t): printTextWithTrivia("%", t);
			case OpAssign(t): printTextWithTrivia("=", t);
			case OpAssignOp(AOpAdd(t)): printTextWithTrivia("+=", t);
			case OpAssignOp(AOpSub(t)): printTextWithTrivia("-=", t);
			case OpAssignOp(AOpMul(t)): printTextWithTrivia("*=", t);
			case OpAssignOp(AOpDiv(t)): printTextWithTrivia("/=", t);
			case OpAssignOp(AOpMod(t)): printTextWithTrivia("%=", t);
			case OpAssignOp(AOpAnd(t)): printTextWithTrivia("&&=", t);
			case OpAssignOp(AOpOr(t)): printTextWithTrivia("||=", t);
			case OpAssignOp(AOpBitAnd(t)): printTextWithTrivia("&=", t);
			case OpAssignOp(AOpBitOr(t)): printTextWithTrivia("|=", t);
			case OpAssignOp(AOpBitXor(t)): printTextWithTrivia("^=", t);
			case OpAssignOp(AOpShl(t)): printTextWithTrivia("<<=", t);
			case OpAssignOp(AOpShr(t)): printTextWithTrivia(">>=", t);
			case OpAssignOp(AOpUshr(t)): printTextWithTrivia(">>>=", t);
			case OpEquals(t): printTextWithTrivia("==", t);
			case OpNotEquals(t): printTextWithTrivia("!=", t);
			case OpStrictEquals(t): printTextWithTrivia("===", t);
			case OpNotStrictEquals(t): printTextWithTrivia("!==", t);
			case OpGt(t): printTextWithTrivia(">", t);
			case OpGte(t): printTextWithTrivia(">=", t);
			case OpLt(t): printTextWithTrivia("<", t);
			case OpLte(t): printTextWithTrivia("<=", t);
			case OpIn(t): printTextWithTrivia("in", t);
			case OpIs(t): printTextWithTrivia("is", t);
			case OpAnd(t): printTextWithTrivia("&&", t);
			case OpOr(t): printTextWithTrivia("||", t);
			case OpShl(t): printTextWithTrivia("<<", t);
			case OpShr(t): printTextWithTrivia(">>", t);
			case OpUshr(t): printTextWithTrivia(">>>", t);
			case OpBitAnd(t): printTextWithTrivia("&", t);
			case OpBitOr(t): printTextWithTrivia("|", t);
			case OpBitXor(t): printTextWithTrivia("^", t);
			case OpComma(t): printTextWithTrivia(",", t);
		}
		printExpr(b);
	}

	function printArrayAccess(a:TArrayAccess) {
		printExpr(a.eobj);
		printOpenBracket(a.syntax.openBracket);
		printExpr(a.eindex);
		printCloseBracket(a.syntax.closeBracket);
	}

	function printVarKind(kind:VarDeclKind) {
		switch (kind) {
			case VVar(t): printTextWithTrivia("var", t);
			case VConst(t): printTextWithTrivia("const", t);
		}
	}

	function printVars(kind:VarDeclKind, vars:Array<TVarDecl>) {
		printVarKind(kind);
		for (v in vars) {
			printTextWithTrivia(v.v.name, v.syntax.name);
			if (v.syntax.type != null) {
				printSyntaxTypeHint(v.syntax.type);
			}
			if (v.init != null) printVarInit(v.init);
			if (v.comma != null) printComma(v.comma);
		}
	}

	function printVarInit(init:TVarInit) {
		printTextWithTrivia("=", init.equalsToken);
		printExpr(init.expr);
	}

	function printObjectDecl(o:TObjectDecl) {
		printOpenBrace(o.syntax.openBrace);
		for (f in o.fields) {
			printTextWithTrivia(f.name, f.syntax.name); // TODO: quoted fields
			printColon(f.syntax.colon);
			printExpr(f.expr);
			if (f.syntax.comma != null) printComma(f.syntax.comma);
		}
		printCloseBrace(o.syntax.closeBrace);
	}

	function printFieldAccess(obj:TFieldObject, name:String, token:Token) {
		switch (obj.kind) {
			case TOExplicit(dot, e):
				printExpr(e);
				printDot(dot);
			case TOImplicitThis(_):
			case TOImplicitClass(_):
		}
		printTextWithTrivia(name, token);
	}

	function printLiteral(l:TLiteral) {
		switch (l) {
			case TLSuper(syntax): printTextWithTrivia("super", syntax);
			case TLThis(syntax): printTextWithTrivia("this", syntax);
			case TLBool(syntax): printTextWithTrivia(syntax.text, syntax);
			case TLNull(syntax): printTextWithTrivia("null", syntax);
			case TLUndefined(syntax): printTextWithTrivia("undefined", syntax);
			case TLInt(syntax): printTextWithTrivia(syntax.text, syntax);
			case TLNumber(syntax): printTextWithTrivia(syntax.text, syntax);
			case TLString(syntax): printTextWithTrivia(syntax.text, syntax);
			case TLRegExp(syntax): printTextWithTrivia(syntax.text, syntax);
		}
	}

	function printBlock(block:TBlock) {
		printOpenBrace(block.syntax.openBrace);
		for (e in block.exprs) {
			printBlockExpr(e);
		}
		printCloseBrace(block.syntax.closeBrace);
	}

	function printBlockExpr(e:TBlockExpr) {
		printExpr(e.expr);
		if (e.semicolon != null) printSemicolon(e.semicolon);
	}
}
