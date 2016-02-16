﻿module sourceGenerators.d.genPrinter;
import fancy_ast;
import fancy_analyzer;
import fancy_util;
import sourceGenerators.d.genVisitor;

string genPrinter (const GrammerAnalyzer.AnalyzedGrammar ag) pure {
	string blrplate=`
string print(const `~ ag.allGroups[0].name.identifier ~` root) pure {
	import std.array;
	struct Printer {
		Appender!(const (char)[]) sink;

		void print(const char c) {
			sink.put([c]);
		}

`;
	string result;

	string genPtrStmt(const PatternElement e) {
		string result;

		if (auto se = cast(StringElement)e) {
			result ~= "sink.put(\"".indentBy(3) ~ se.string_ ~ "\");\n";
		} else if (auto oe = cast(ConditionalElement)e) {
				if (oe.elem.isASTMember) {

				result ~= "if (g.".indentBy(3) ~ getName(oe.elem) 
					~ ") {\n";
				foreach(le;oe.ce) { 
					result ~= genPtrStmt(le);
				}
				result ~= genPtrStmt(oe.elem)
					~ "}\n".indentBy(3);
			}
			} else if (auto alte = cast(AlternativeElement)e) {
				foreach (alt;astMembers(alte)) {
					result ~= "if (g.".indentBy(3) ~ getName(alt) 
						~ ") {\n" ~ genPtrStmt(alt) 
						~ "}".indentBy(3);
				}
			} else if (auto ne = cast(NamedElement)e) {
				if (ne.isArray) {
				result ~= "foreach(_e;".indentBy(3)
				~ "g." ~ getName(e) ~ ") {\n"
				~	"print(_e".indentBy(4) 
				~ ");\n";
				if (ne.lst_sep) {
					result ~= "sink.put(\"".indentBy(4)
					~ ne.lst_sep.string_ ~ "\");\n";
				}
				result ~= "}".indentBy(3) ~ "\n";
			} else {
				result ~= "print(g.".indentBy(3) 
					~ getName(e) ~ ");\n";
			} 
		} else if (auto ce = cast(NamedChar)e) {
			if (ce.isArray) {
				result ~= "foreach(_e;".indentBy(3)
					~ "g." ~ getName(e) ~ ") {\n"
						~	"print(_e".indentBy(4) 
						~ ");\n";
				result ~= "}".indentBy(3) ~ "\n";
			} else {
				result ~= "print(g.".indentBy(3) 
					~ getName(e) ~ ");\n";
			} 
		} else {
			//assert(0);
		}
				

		return result;
	}

	foreach(eG;ag.allGroups.getElementGroups) {
		result ~= "\n\n" ~ "void print(".indentBy(2)
			~ eG.name.identifier ~ " g) {\n";
		foreach(elm;eG.elements) {
			result ~= genPtrStmt(elm);
			result ~= "sink.put(\" \");\n".indentBy(3);
		}
		result ~= "}\n".indentBy(2);
	}

	return  blrplate ~ genVisitor(ag.allGroups,"void","print",2) ~ result  ~ "\n\t}"
		~ "\n\tauto ptr = Printer();\n\tptr.print(cast(" ~ ag.allGroups[0].name.identifier ~ 
		")root);\n\treturn cast(string)ptr.sink.data;"
			~ "\n}\n";

}
