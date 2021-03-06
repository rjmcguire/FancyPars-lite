version(Have_vibe_d) {
import vibe.d;
void getIndex(HTTPServerRequest req, HTTPServerResponse res) {
	res.writeBody(`<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
	<head>
		<title> FancyPars(e) </title> 
	</head>
	<body>
		<h1> Welcome to FancyPars </h1>
		<p> <a href="/generateParser"> generate Parser </a> </p>
	</body>
</html>`, "text/html");
}

void getGenerateParser(HTTPServerRequest req, HTTPServerResponse res) {
	res.writeBody(`<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html><head>  
  <meta content="text/html; charset=ISO-8859-1" http-equiv="content-type"> <title>fancyForm</title></head><body>
<form method="post" name="fancyForm" action="/generateParser" enctype="multipart/form-data">
  <p> <textarea cols="80" rows="25" name="grammar">ASTNode {
    Identifier @internal {
        [a-zA-Z_][] identifier
    }

    Group @parent {
        Identifier name, ? "@" : Identifier[] annotations : "@", "{",
            PatternElement[] elements : "," / Group[] groups,
             "}"
    }   

    PatternElement @internal {

        AlternativeElement @noFirst {
            PatternElement[] alternatives : "/"
        }

        LexerElement {

            StringElement {
                "\"", char[] string_, "\""
            }

            NamedChar {
                "char", ? "[]" : bool isArray, Identifier name
            }

            CharRange @internal {
                char rangeBegin,  ? "-" : char RangeEnd
            }

            RangeElement {
                "[", CharRange[] ranges, "]"
            }

            LookbehindElement {
                "?lb", "(", StringElement str, ")"
            }

            NotElement {
                "!", LexerElement ce
            }

        }

        NamedElement {
            Identifier type,  ? "[]" : bool isArray, Identifier name, 
            ? bool isArray : ? ":" : StringElement lst_sep
        }

        ParenElement {
            "(", PatternElement[] elements : ",", ")" 
        }

        FlagElement {
            "bool", Identifier flag_name
        }

        QueryElement {
            "?", "bool", Identifier flag_name, ":", PatternElement elem
        }

        OptionalElement {
            "?", LexerElement[] ce : ",", ":", PatternElement elem
        }

    }
}

</textarea> </p>
 <p> <input value="Generate AST" type="submit"> </p>
</form>
</body></html>`,"text/html");
}

void postGenerateParser(HTTPServerRequest req, HTTPServerResponse res) {
	
	auto ag = req.form["grammar"].lex.parse.analyze;
	auto zipdl = new ZipArchive;
//	foreach(i,n;["ast.d","lexer.d","parser.d","printer.d"]) {
//		ArchiveMember member() = new ArchiveMember();
//		zipdl.addMember()
//	}
	
	res.writeBody("\n/***AST***/\n" ~ ag.genAST 
		~ "\n/***Token***/\n" ~ ag.genTokenTypeEnum 

		~ "\n/***Lexer***/\n" ~ lexer_blrplate_head 
		~ ag.genLex ~ lexer_blrplate_tail 

		~ "\n/***Parser***/\n" ~ ag.genPars

		/+~ "\n/***Printer***/\n" ~ ag.genPrinter+/);
	res.writeBody(serializeToJson(ag).toPrettyString);
}

shared static this()
{
	auto router = new URLRouter;
	router.get("/",&getIndex);
	router.get("/generateParser",&getGenerateParser);
	router.post("/generateParser",&postGenerateParser);


	router.get("*", serveStaticFiles("public/"));
	auto settings = new HTTPServerSettings;
	//settings.bindAddresses = ["::1", "127.0.0.1"];
	settings.sessionStore = new MemorySessionStore();
	settings.port = 8081;
	listenHTTP(settings, router);

	logInfo("Please open http://127.0.0.1:8081/ in your browser.");
}


void hello(HTTPServerRequest req, HTTPServerResponse res)
{
	res.writeBody("Hello, World!");
}
}
