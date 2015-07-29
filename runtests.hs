
import Data.List (intercalate)
import Test.Framework (defaultMain, testGroup, Test)
import Test.Framework.Providers.HUnit
import Test.HUnit hiding (Test)

import Language.JavaScript.Parser
import Language.JavaScript.Parser.Grammar5
import Language.JavaScript.Parser.Lexer
import Language.JavaScript.Parser.Parser


main :: IO ()
main = defaultMain
    [ lexerSuite
    , testSuite
    , commentPrintSuite
    , pendingSuite
    ]


pendingSuite :: Test
pendingSuite = testGroup "Pending"
    [
    ]

lexerSuite :: Test
lexerSuite = testGroup "Lexer"
    [ testCase "assign1"    (testLexer "x=1"            "[IdentifierToken,SimpleAssignToken,DecimalToken]")
    , testCase "assign2"    (testLexer "x=1\ny=2"       "[IdentifierToken,SimpleAssignToken,DecimalToken,WsToken,IdentifierToken,SimpleAssignToken,DecimalToken]")
    , testCase "break"      (testLexer "break\nx=1"     "[BreakToken,WsToken,IdentifierToken,SimpleAssignToken,DecimalToken]")
    , testCase "return"     (testLexer "return\nx=1"    "[ReturnToken,WsToken,IdentifierToken,SimpleAssignToken,DecimalToken]")
    ]

testSuite :: Test
testSuite = testGroup "Parser"
    [ testCase "helloWorld"         caseHelloWorld
    , testCase "LiteralNull"        (testLiteral "null"     "Right (JSSourceElementsTop [JSLiteral 'null'])")
    , testCase "LiteralFalse"       (testLiteral "false"    "Right (JSSourceElementsTop [JSLiteral 'false'])")
    , testCase "LiteralTrue"        (testLiteral "true"     "Right (JSSourceElementsTop [JSLiteral 'true'])")
    , testCase "LiteralHexInteger1" (testLiteral "0x1234fF" "Right (JSSourceElementsTop [JSHexInteger '0x1234fF'])")
    , testCase "LiteralHexInteger2" (testLiteral "0X1234fF" "Right (JSSourceElementsTop [JSHexInteger '0X1234fF'])")
    , testCase "LiteralDecimal1"    (testLiteral "1.0e4"    "Right (JSSourceElementsTop [JSDecimal '1.0e4'])")
    , testCase "LiteralDecimal2"    (testLiteral "2.3E6"    "Right (JSSourceElementsTop [JSDecimal '2.3E6'])")
    , testCase "LiteralDecimal3"    (testLiteral "4.5"      "Right (JSSourceElementsTop [JSDecimal '4.5'])")
    , testCase "LiteralDecimal3"    (testLiteral "0.7e8"    "Right (JSSourceElementsTop [JSDecimal '0.7e8'])")
    , testCase "LiteralDecimal4"    (testLiteral "0.7E8"    "Right (JSSourceElementsTop [JSDecimal '0.7E8'])")
    , testCase "LiteralDecimal5"    (testLiteral "10"       "Right (JSSourceElementsTop [JSDecimal '10'])")
    , testCase "LiteralDecimal6"    (testLiteral "0"        "Right (JSSourceElementsTop [JSDecimal '0'])")
    , testCase "LiteralDecimal7"    (testLiteral "0.03"     "Right (JSSourceElementsTop [JSDecimal '0.03'])")
    , testCase "LiteralDecimal9"    (testLiteral "0.7e+8"   "Right (JSSourceElementsTop [JSDecimal '0.7e+8'])")
    , testCase "LiteralDecimal10"   (testLiteral "0.7e-18"  "Right (JSSourceElementsTop [JSDecimal '0.7e-18'])")
    , testCase "LiteralDecimal11"   (testLiteral "1.0e+4"   "Right (JSSourceElementsTop [JSDecimal '1.0e+4'])")
    , testCase "LiteralDecimal12"   (testLiteral "1.0e-4"   "Right (JSSourceElementsTop [JSDecimal '1.0e-4'])")
    , testCase "LiteralDecimal13"   (testLiteral "1e18"     "Right (JSSourceElementsTop [JSDecimal '1e18'])")
    , testCase "LiteralDecimal14"   (testLiteral "1e+18"    "Right (JSSourceElementsTop [JSDecimal '1e+18'])")
    , testCase "LiteralDecimal15"   (testLiteral "1e-18"    "Right (JSSourceElementsTop [JSDecimal '1e-18'])")
    , testCase "LiteralDecimal16"   (testLiteral "1E-01"    "Right (JSSourceElementsTop [JSDecimal '1E-01'])")

    , testCase "LiteralOctal"       (testLiteral "010"      "Right (JSSourceElementsTop [JSOctal \"010\"])")

    , testCase "LiteralString1"     (testLiteral "\"hello\\nworld\"" "Right (JSSourceElementsTop [JSStringLiteralD 'hello\\nworld'])")
    , testCase "LiteralString2"     (testLiteral "'hello\\nworld'"  "Right (JSSourceElementsTop [JSStringLiteralS 'hello\\nworld'])")

    , testCase "LiteralThis"        (testPE "this"  "Right (JSSourceElementsTop [JSLiteral 'this'])")

    , testCase "LiteralRegex1"      (testPE "/blah/"  "Right (JSSourceElementsTop [JSRegEx \"/blah/\"])")
    , testCase "LiteralRegex2"      (testPE "/$/g"    "Right (JSSourceElementsTop [JSRegEx \"/$/g\"])")
    , testCase "LiteralRegex3"      (testPE "/\\n/g"  "Right (JSSourceElementsTop [JSRegEx \"/\\\\n/g\"])")
    , testCase "LiteralRegex4"      (testPE "/^\"(?:\\.|[^\"])*\"|^'(?:[^']|\\.)*'/" "Right (JSSourceElementsTop [JSRegEx \"/^\\\"(?:\\\\.|[^\\\"])*\\\"|^'(?:[^']|\\\\.)*'/\"])")

    , testCase "Identifier1"        (testPE "_$"      "Right (JSSourceElementsTop [JSIdentifier '_$'])")
    , testCase "Identifier2"        (testPE "this_"   "Right (JSSourceElementsTop [JSIdentifier 'this_'])")

    , testCase "ArrayLiteral1"      (testPE "[]"      "Right (JSSourceElementsTop [JSArrayLiteral []])")
    , testCase "ArrayLiteral2"      (testPE "[,]"     "Right (JSSourceElementsTop [JSArrayLiteral [JSComma]])")
    , testCase "ArrayLiteral3"      (testPE "[,,]"    "Right (JSSourceElementsTop [JSArrayLiteral [JSComma,JSComma]])")
    , testCase "ArrayLiteral4"      (testPE "[,,x]"   "Right (JSSourceElementsTop [JSArrayLiteral [JSComma,JSComma,JSIdentifier 'x']])")
    , testCase "ArrayLiteral5"      (testPE "[,,x]"   "Right (JSSourceElementsTop [JSArrayLiteral [JSComma,JSComma,JSIdentifier 'x']])")
    , testCase "ArrayLiteral6"      (testPE "[,x,,x]" "Right (JSSourceElementsTop [JSArrayLiteral [JSComma,JSIdentifier 'x',JSComma,JSComma,JSIdentifier 'x']])")
    , testCase "ArrayLiteral7"      (testPE "[x]"     "Right (JSSourceElementsTop [JSArrayLiteral [JSIdentifier 'x']])")
    , testCase "ArrayLiteral8"      (testPE "[x,]"    "Right (JSSourceElementsTop [JSArrayLiteral [JSIdentifier 'x',JSComma]])")
    , testCase "ArrayLiteral9"      (testPE "[,,,]"   "Right (JSSourceElementsTop [JSArrayLiteral [JSComma,JSComma,JSComma]])")
    , testCase "ArrayLiteral10"     (testPE "[a,,]"   "Right (JSSourceElementsTop [JSArrayLiteral [JSIdentifier 'a',JSComma,JSComma]])")

    , testCase "ObjectLiteral1"     (testPE "{}"        "Right (JSSourceElementsTop [JSObjectLiteral []])")
    , testCase "ObjectLiteral2"     (testPE "{x:1}"     "Right (JSSourceElementsTop [JSObjectLiteral [JSPropertyNameandValue (JSIdentifier 'x') [JSDecimal '1']]])")
    , testCase "ObjectLiteral3"     (testPE "{x:1,y:2}" "Right (JSSourceElementsTop [JSObjectLiteral [JSPropertyNameandValue (JSIdentifier 'x') [JSDecimal '1'],JSComma,JSPropertyNameandValue (JSIdentifier 'y') [JSDecimal '2']]])")

    , testCase "ObjectLiteral4"     (testPE "{evaluate:evaluate,load:function load(s){if(x)return s;1}}" "Right (JSSourceElementsTop [JSObjectLiteral [JSPropertyNameandValue (JSIdentifier 'evaluate') [JSIdentifier 'evaluate'],JSComma,JSPropertyNameandValue (JSIdentifier 'load') [JSFunctionExpression \"load\" (JSIdentifier 's') (JSStatementBlock [JSIf (JSIdentifier 'x') (JSReturn JSIdentifier 's' JSSemicolon),JSDecimal '1']))]]])")

    , testCase "ObjectLiteral5"     (testPE "{x:1,}"    "Right (JSSourceElementsTop [JSObjectLiteral [JSPropertyNameandValue (JSIdentifier 'x') [JSDecimal '1'],JSComma]])")

    , testCase "ObjectLiteral6"     (testProg "a={\n  values: 7,\n}\n" "Right (JSSourceElementsTop [JSOpAssign ('=',JSIdentifier 'a',JSObjectLiteral [JSPropertyNameandValue (JSIdentifier 'values') [JSDecimal '7'],JSComma])])")

    -- Edition 5 extensions
    , testCase "ObjectLiteral7"     (testProg "x={get foo() {return 1},set foo(a) {x=a}}" "Right (JSSourceElementsTop [JSOpAssign ('=',JSIdentifier 'x',JSObjectLiteral [JSPropertyAccessor JSAccessorGet (JSIdentifier 'foo') [] (JSStatementBlock [JSReturn JSDecimal '1' ]),JSComma,JSPropertyAccessor JSAccessorSet (JSIdentifier 'foo') [JSIdentifier 'a'] (JSStatementBlock [JSOpAssign ('=',JSIdentifier 'x',JSIdentifier 'a')])])])")

    , testCase "ObjectLiteral8"     (testProg "a={if:1,interface:2}" "Right (JSSourceElementsTop [JSOpAssign ('=',JSIdentifier 'a',JSObjectLiteral [JSPropertyNameandValue (JSIdentifier 'if') [JSDecimal '1'],JSComma,JSPropertyNameandValue (JSIdentifier 'interface') [JSDecimal '2']])])")

    , testCase "OpPrecedence"       (testProg "2+3*4+5"  "Right (JSSourceElementsTop [JSExpressionBinary (\"+\",JSExpressionBinary (\"+\",JSDecimal '2',JSExpressionBinary (\"*\",JSDecimal '3',JSDecimal '4')),JSDecimal '5')])")

    , testCase "ExpressionParen"    (testPE "(56)"     "Right (JSSourceElementsTop [JSExpressionParen (JSDecimal '56')])")

    , testCase "Statement1"         (testStmt "x"        "Right (JSSourceElementsTop [JSIdentifier 'x'])")
    , testCase "Statement2"         (testStmt "null"     "Right (JSSourceElementsTop [JSLiteral 'null'])")
    , testCase "Statement3"         (testStmt "true?1:2" "Right (JSSourceElementsTop [JSExpressionTernary (JSLiteral 'true',JSDecimal '1',JSDecimal '2')])")

    , testCase "Statement4"         (testStmt "x||y"     "Right (JSSourceElementsTop [JSExpressionBinary (\"||\",JSIdentifier 'x',JSIdentifier 'y')])")
    , testCase "Statement5"         (testStmt "x&&y"     "Right (JSSourceElementsTop [JSExpressionBinary (\"&&\",JSIdentifier 'x',JSIdentifier 'y')])")
    , testCase "Statement6"         (testStmt "x|y"     "Right (JSSourceElementsTop [JSExpressionBinary (\"|\",JSIdentifier 'x',JSIdentifier 'y')])")
    , testCase "Statement6"         (testStmt "x^y"     "Right (JSSourceElementsTop [JSExpressionBinary (\"^\",JSIdentifier 'x',JSIdentifier 'y')])")
    , testCase "Statement7"         (testStmt "x&y"     "Right (JSSourceElementsTop [JSExpressionBinary (\"&\",JSIdentifier 'x',JSIdentifier 'y')])")

    , testCase "Statement8"         (testStmt "x==y"     "Right (JSSourceElementsTop [JSExpressionBinary (\"==\",JSIdentifier 'x',JSIdentifier 'y')])")
    , testCase "Statement9"         (testStmt "x!=y"     "Right (JSSourceElementsTop [JSExpressionBinary (\"!=\",JSIdentifier 'x',JSIdentifier 'y')])")
    , testCase "Statement10"        (testStmt "x===y"     "Right (JSSourceElementsTop [JSExpressionBinary (\"===\",JSIdentifier 'x',JSIdentifier 'y')])")
    , testCase "Statement11"        (testStmt "x!==y"     "Right (JSSourceElementsTop [JSExpressionBinary (\"!==\",JSIdentifier 'x',JSIdentifier 'y')])")

    , testCase "Statement12"        (testStmt "x<y"     "Right (JSSourceElementsTop [JSExpressionBinary (\"<\",JSIdentifier 'x',JSIdentifier 'y')])")
    , testCase "Statement12"        (testStmt "x>y"     "Right (JSSourceElementsTop [JSExpressionBinary (\">\",JSIdentifier 'x',JSIdentifier 'y')])")
    , testCase "Statement12"        (testStmt "x<=y"     "Right (JSSourceElementsTop [JSExpressionBinary (\"<=\",JSIdentifier 'x',JSIdentifier 'y')])")
    , testCase "Statement12"        (testStmt "x>=y"     "Right (JSSourceElementsTop [JSExpressionBinary (\">=\",JSIdentifier 'x',JSIdentifier 'y')])")
    , testCase "Statement12"        (testStmt "x instanceof y"  "Right (JSSourceElementsTop [JSExpressionBinary (\"instanceof\",JSIdentifier 'x',JSIdentifier 'y')])")

    , testCase "Statement13"        (testStmt "x<<y"     "Right (JSSourceElementsTop [JSExpressionBinary (\"<<\",JSIdentifier 'x',JSIdentifier 'y')])")
    , testCase "Statement13"        (testStmt "x>>y"     "Right (JSSourceElementsTop [JSExpressionBinary (\">>\",JSIdentifier 'x',JSIdentifier 'y')])")
    , testCase "Statement13"        (testStmt "x>>>y"     "Right (JSSourceElementsTop [JSExpressionBinary (\">>>\",JSIdentifier 'x',JSIdentifier 'y')])")

    , testCase "Statement14"        (testStmt "x+y"     "Right (JSSourceElementsTop [JSExpressionBinary (\"+\",JSIdentifier 'x',JSIdentifier 'y')])")
    , testCase "Statement14"        (testStmt "x-y"     "Right (JSSourceElementsTop [JSExpressionBinary (\"-\",JSIdentifier 'x',JSIdentifier 'y')])")

    , testCase "Statement15"        (testStmt "x*y"     "Right (JSSourceElementsTop [JSExpressionBinary (\"*\",JSIdentifier 'x',JSIdentifier 'y')])")
    , testCase "Statement16"        (testStmt "x/y"     "Right (JSSourceElementsTop [JSExpressionBinary (\"/\",JSIdentifier 'x',JSIdentifier 'y')])")
    , testCase "Statement17"        (testStmt "x%y"     "Right (JSSourceElementsTop [JSExpressionBinary (\"%\",JSIdentifier 'x',JSIdentifier 'y')])")

    , testCase "Statement18"        (testStmt "delete y"  "Right (JSSourceElementsTop [JSUnaryExpression (\"delete \",JSIdentifier 'y')])")
    , testCase "Statement19"        (testStmt "void y"    "Right (JSSourceElementsTop [JSUnaryExpression (\"void \",JSIdentifier 'y')])")
    , testCase "Statement20"        (testStmt "typeof y"  "Right (JSSourceElementsTop [JSUnaryExpression (\"typeof \",JSIdentifier 'y')])")
    , testCase "Statement21"        (testStmt "++y"    "Right (JSSourceElementsTop [JSUnaryExpression (\"++\",JSIdentifier 'y')])")
    , testCase "Statement22"        (testStmt "--y"    "Right (JSSourceElementsTop [JSUnaryExpression (\"--\",JSIdentifier 'y')])")
    , testCase "Statement23"        (testStmt "+y"     "Right (JSSourceElementsTop [JSUnaryExpression (\"+\",JSIdentifier 'y')])")
    , testCase "Statement24"        (testStmt "-y"     "Right (JSSourceElementsTop [JSUnaryExpression (\"-\",JSIdentifier 'y')])")
    , testCase "Statement25"        (testStmt "~y"     "Right (JSSourceElementsTop [JSUnaryExpression (\"~\",JSIdentifier 'y')])")
    , testCase "Statement26"        (testStmt "!y"     "Right (JSSourceElementsTop [JSUnaryExpression (\"!\",JSIdentifier 'y')])")

    , testCase "Statement27"        (testStmt "y++"     "Right (JSSourceElementsTop [JSExpressionPostfix (\"++\",JSIdentifier 'y')])")
    , testCase "Statement28"        (testStmt "y--"     "Right (JSSourceElementsTop [JSExpressionPostfix (\"--\",JSIdentifier 'y')])")

    -- Member Expressions
    , testCase "MemberExpression1a" (testStmt "function(){}"     "Right (JSSourceElementsTop [JSFunctionExpression \"\" () (JSStatementBlock []))])")
    , testCase "MemberExpression1b" (testStmt "function(a){}"    "Right (JSSourceElementsTop [JSFunctionExpression \"\" (JSIdentifier 'a') (JSStatementBlock []))])")
    , testCase "MemberExpression1c" (testStmt "function(a,b){}"  "Right (JSSourceElementsTop [JSFunctionExpression \"\" (JSIdentifier 'a',JSIdentifier 'b') (JSStatementBlock []))])")
    , testCase "MemberExpression1d" (testStmt "x[y]"     "Right (JSSourceElementsTop [JSMemberSquare (JSIdentifier 'x',JSIdentifier 'y')])")
    , testCase "MemberExpression1e" (testStmt "x[y][z]"  "Right (JSSourceElementsTop [JSMemberSquare (JSMemberSquare (JSIdentifier 'x',JSIdentifier 'y'),JSIdentifier 'z')])")
    , testCase "MemberExpression1f" (testStmt "x.y"      "Right (JSSourceElementsTop [JSMemberDot (JSIdentifier 'x',JSIdentifier 'y')])")
    , testCase "MemberExpression1g" (testStmt "x.y.z"    "Right (JSSourceElementsTop [JSMemberDot (JSMemberDot (JSIdentifier 'x',JSIdentifier 'y'),JSIdentifier 'z')])")
    , testCase "MemberExpression1h" (testStmt "new x()"  "Right (JSSourceElementsTop [JSMemberNew (JSIdentifier 'x',JSArguments ())])")

    , testCase "NewExpression1" (testStmt "new x.y"  "Right (JSSourceElementsTop [JSNewExpression JSMemberDot (JSIdentifier 'x',JSIdentifier 'y')])")

    , testCase "CallExpression1" (testStmt "x()"         "Right (JSSourceElementsTop [JSMemberExpression (JSIdentifier 'x',JSArguments ())])")
    , testCase "CallExpression2" (testStmt "x()()"       "Right (JSSourceElementsTop [JSCallExpression (JSMemberExpression (JSIdentifier 'x',JSArguments ()),JSArguments ())])")
    , testCase "CallExpression3" (testStmt "x()[4]"      "Right (JSSourceElementsTop [JSCallExpressionSquare (JSMemberExpression (JSIdentifier 'x',JSArguments ()),JSDecimal '4')])")
    , testCase "CallExpression4" (testStmt "x().x"       "Right (JSSourceElementsTop [JSCallExpressionDot (JSMemberExpression (JSIdentifier 'x',JSArguments ()),JSIdentifier 'x')])")
    , testCase "CallExpression5" (testStmt "x(a,b=2).x"  "Right (JSSourceElementsTop [JSCallExpressionDot (JSMemberExpression (JSIdentifier 'x',JSArguments (JSIdentifier 'a',JSOpAssign ('=',JSIdentifier 'b',JSDecimal '2'))),JSIdentifier 'x')])")

    , testCase "AssignExpression1"  (testStmt "x=1"    "Right (JSSourceElementsTop [JSOpAssign ('=',JSIdentifier 'x',JSDecimal '1')])")
    , testCase "AssignExpression2"  (testStmt "x*=1"   "Right (JSSourceElementsTop [JSOpAssign ('*=',JSIdentifier 'x',JSDecimal '1')])")
    , testCase "AssignExpression3"  (testStmt "x/=1"   "Right (JSSourceElementsTop [JSOpAssign ('/=',JSIdentifier 'x',JSDecimal '1')])")
    , testCase "AssignExpression4"  (testStmt "x%=1"   "Right (JSSourceElementsTop [JSOpAssign ('%=',JSIdentifier 'x',JSDecimal '1')])")
    , testCase "AssignExpression5"  (testStmt "x+=1"   "Right (JSSourceElementsTop [JSOpAssign ('+=',JSIdentifier 'x',JSDecimal '1')])")
    , testCase "AssignExpression6"  (testStmt "x-=1"   "Right (JSSourceElementsTop [JSOpAssign ('-=',JSIdentifier 'x',JSDecimal '1')])")
    , testCase "AssignExpression7"  (testStmt "x<<=1"  "Right (JSSourceElementsTop [JSOpAssign ('<<=',JSIdentifier 'x',JSDecimal '1')])")
    , testCase "AssignExpression8"  (testStmt "x>>=1"  "Right (JSSourceElementsTop [JSOpAssign ('>>=',JSIdentifier 'x',JSDecimal '1')])")
    , testCase "AssignExpression9"  (testStmt "x>>>=1" "Right (JSSourceElementsTop [JSOpAssign ('>>>=',JSIdentifier 'x',JSDecimal '1')])")
    , testCase "AssignExpression10" (testStmt "x&=1"   "Right (JSSourceElementsTop [JSOpAssign ('&=',JSIdentifier 'x',JSDecimal '1')])")
    , testCase "AssignExpression11" (testStmt "x^=1"   "Right (JSSourceElementsTop [JSOpAssign ('^=',JSIdentifier 'x',JSDecimal '1')])")
    , testCase "AssignExpression12" (testStmt "x|=1"   "Right (JSSourceElementsTop [JSOpAssign ('|=',JSIdentifier 'x',JSDecimal '1')])")

    , testCase "Block1" (testStmt "{}"        "Right (JSSourceElementsTop [JSStatementBlock []])")
    , testCase "Block2" (testStmt "{x=1}"     "Right (JSSourceElementsTop [JSStatementBlock [JSOpAssign ('=',JSIdentifier 'x',JSDecimal '1')]])")
    , testCase "Block3" (testStmt "{x=1;y=2}" "Right (JSSourceElementsTop [JSStatementBlock [JSOpAssign ('=',JSIdentifier 'x',JSDecimal '1'),JSSemicolon,JSOpAssign ('=',JSIdentifier 'y',JSDecimal '2')]])")
    , testCase "Block4" (testStmt "{{}}"      "Right (JSSourceElementsTop [JSStatementBlock [JSStatementBlock []]])")
    , testCase "Block5" (testStmt "{{{}}}"    "Right (JSSourceElementsTop [JSStatementBlock [JSStatementBlock [JSStatementBlock []]]])")

    , testCase "If1" (testStmt "if (1) {}"  "Right (JSSourceElementsTop [JSIf (JSDecimal '1') (JSStatementBlock [])])")

    , testCase "IfElse1" (testStmt "if (1) {} else {}"     "Right (JSSourceElementsTop [JSIf (JSDecimal '1') (JSStatementBlock []) (JSStatementBlock [])])")
    , testCase "IfElse2" (testStmt "if (1) x=1; else {}"   "Right (JSSourceElementsTop [JSIf (JSDecimal '1') (JSOpAssign ('=',JSIdentifier 'x',JSDecimal '1'),JSSemicolon) (JSStatementBlock [])])")

    , testCase "DoWhile1" (testStmt "do {x=1} while (true);"  "Right (JSSourceElementsTop [JSDoWhile (JSStatementBlock [JSOpAssign ('=',JSIdentifier 'x',JSDecimal '1')]) (JSLiteral 'true') (JSSemicolon)])")
    , testCase "DoWhile2" (testStmt "do x=x+1;while(x<4);"    "Right (JSSourceElementsTop [JSDoWhile (JSOpAssign ('=',JSIdentifier 'x',JSExpressionBinary (\"+\",JSIdentifier 'x',JSDecimal '1')),JSSemicolon) (JSExpressionBinary (\"<\",JSIdentifier 'x',JSDecimal '4')) (JSSemicolon)])")

    , testCase "While1"     (testStmt "while(true);"            "Right (JSSourceElementsTop [JSWhile (JSLiteral 'true') ()])")

    , testCase "For1"       (testStmt "for(;;);"             "Right (JSSourceElementsTop [JSFor [] [] [] ()])")
    , testCase "For2"       (testStmt "for(x=1;x<10;x++);"   "Right (JSSourceElementsTop [JSFor [JSOpAssign ('=',JSIdentifier 'x',JSDecimal '1')] [JSExpressionBinary (\"<\",JSIdentifier 'x',JSDecimal '10')] [JSExpressionPostfix (\"++\",JSIdentifier 'x')] ()])")

    , testCase "ForVar1"    (testStmt "for(var x;;);"        "Right (JSSourceElementsTop [JSForVar [JSVarDecl (JSIdentifier 'x') ] [] [] ()])")
    , testCase "ForVar2a"   (testStmt "for(var x=1;;);"      "Right (JSSourceElementsTop [JSForVar [JSVarDecl (JSIdentifier 'x') [JSDecimal '1']] [] [] ()])")
    , testCase "ForVar2b"   (testStmt "for(var x;y;z){}"     "Right (JSSourceElementsTop [JSForVar [JSVarDecl (JSIdentifier 'x') ] [JSIdentifier 'y'] [JSIdentifier 'z'] (JSStatementBlock [])])")

    , testCase "ForIn1"     (testStmt "for(x in 5){}"        "Right (JSSourceElementsTop [JSForIn JSIdentifier 'x' (JSDecimal '5') (JSStatementBlock [])])")

    , testCase "ForVarIn1"  (testStmt "for(var x in 5){}"    "Right (JSSourceElementsTop [JSForVarIn (JSVarDecl (JSIdentifier 'x') ) (JSDecimal '5') (JSStatementBlock [])])")

    , testCase "Var1" (testStmt "var x=1;"          "Right (JSSourceElementsTop [JSVariable var [JSVarDecl (JSIdentifier 'x') [JSDecimal '1']]])")
    , testCase "Var2" (testStmt "const x=1,y=2;"    "Right (JSSourceElementsTop [JSConstant [JSVarDecl (JSIdentifier 'x') [JSDecimal '1'],JSComma,JSVarDecl (JSIdentifier 'y') [JSDecimal '2']]])")

    , testCase "Continue1" (testStmt "continue;"    "Right (JSSourceElementsTop [JSContinue,JSSemicolon])")
    , testCase "Continue2" (testStmt "continue x;"  "Right (JSSourceElementsTop [JSContinue \"x\",JSSemicolon])")

    , testCase "Break1" (testStmt "break;"          "Right (JSSourceElementsTop [JSBreak,JSSemicolon])")
    , testCase "Break2" (testStmt "break x;"        "Right (JSSourceElementsTop [JSBreak \"x\",JSSemicolon])")

    , testCase "Return1" (testStmt "return;"        "Right (JSSourceElementsTop [JSReturn JSSemicolon])")
    , testCase "Return2" (testStmt "return x;"      "Right (JSSourceElementsTop [JSReturn JSIdentifier 'x' JSSemicolon])")
    , testCase "Return3" (testStmt "return 123;"    "Right (JSSourceElementsTop [JSReturn JSDecimal '123' JSSemicolon])")

    , testCase "With1" (testStmt "with (x) {};"     "Right (JSSourceElementsTop [JSWith (JSIdentifier 'x') JSStatementBlock []JSSemicolon])")

    , testCase "Labelled1" (testStmt "abc:x=1"      "Right (JSSourceElementsTop [JSLabelled (JSIdentifier 'abc') (JSOpAssign ('=',JSIdentifier 'x',JSDecimal '1'))])")

    , testCase "Switch1" (testStmt "switch (x) {}"                "Right (JSSourceElementsTop [JSSwitch (JSIdentifier 'x') []])" )
    , testCase "Switch2" (testStmt "switch (x) {case 1:break;}"   "Right (JSSourceElementsTop [JSSwitch (JSIdentifier 'x') [JSCase (JSDecimal '1') ([JSBreak,JSSemicolon])]])")
    , testCase "Switch3" (testStmt "switch (x) {case 0:\ncase 1:break;}"  "Right (JSSourceElementsTop [JSSwitch (JSIdentifier 'x') [JSCase (JSDecimal '0') ([]),JSCase (JSDecimal '1') ([JSBreak,JSSemicolon])]])")
    , testCase "Switch4" (testStmt "switch (x) {default:break;}"          "Right (JSSourceElementsTop [JSSwitch (JSIdentifier 'x') [JSDefault ([JSBreak,JSSemicolon])]])")
    , testCase "Switch5" (testStmt "switch (x) {default:\ncase 1:break;}" "Right (JSSourceElementsTop [JSSwitch (JSIdentifier 'x') [JSDefault ([]),JSCase (JSDecimal '1') ([JSBreak,JSSemicolon])]])")

    , testCase "Throw1" (testStmt "throw 1"   "Right (JSSourceElementsTop [JSThrow (JSDecimal '1')])")

    , testCase "Try1" (testStmt "try{}catch(a){}"             "Right (JSSourceElementsTop [JSTry (JSStatementBlock [],[JSCatch (JSIdentifier 'a',JSStatementBlock [])],JSFinally ())])")
    , testCase "Try2" (testStmt "try{}finally{}"              "Right (JSSourceElementsTop [JSTry (JSStatementBlock [],[],JSFinally (JSStatementBlock []))])")
    , testCase "Try3" (testStmt "try{}catch(a){}finally{}"    "Right (JSSourceElementsTop [JSTry (JSStatementBlock [],[JSCatch (JSIdentifier 'a',JSStatementBlock [])],JSFinally (JSStatementBlock []))])")

    , testCase "Try4" (testStmt "try{}catch(a){}catch(b){}finally{}"   "Right (JSSourceElementsTop [JSTry (JSStatementBlock [],[JSCatch (JSIdentifier 'a',JSStatementBlock []),JSCatch (JSIdentifier 'b',JSStatementBlock [])],JSFinally (JSStatementBlock []))])")
    , testCase "Try5" (testStmt "try{}catch(a){}catch(b){}"            "Right (JSSourceElementsTop [JSTry (JSStatementBlock [],[JSCatch (JSIdentifier 'a',JSStatementBlock []),JSCatch (JSIdentifier 'b',JSStatementBlock [])],JSFinally ())])")
    , testCase "Try6" (testStmt "try{}catch(a if true){}catch(b){}"    "Right (JSSourceElementsTop [JSTry (JSStatementBlock [],[JSCatch (JSIdentifier 'a') if JSLiteral 'true' (JSStatementBlock []),JSCatch (JSIdentifier 'b',JSStatementBlock [])],JSFinally ())])")

    , testCase "Function1" (testProg "function a(){}"     "Right (JSSourceElementsTop [JSFunction \"a\" () (JSStatementBlock [])])")
    , testCase "Function2" (testProg "function a(b,c){}"  "Right (JSSourceElementsTop [JSFunction \"a\" (JSIdentifier 'b',JSIdentifier 'c') (JSStatementBlock [])])")

    , testCase "Comment1" (testProg "//blah\nx=1;//foo\na"   "Right (JSSourceElementsTop [JSOpAssign ('=',JSIdentifier 'x',JSDecimal '1'),JSSemicolon,JSIdentifier 'a'])")

    , testCase "Comment2" (testProg "/*x=1\ny=2\n*/z=2;//foo\na"  "Right (JSSourceElementsTop [JSOpAssign ('=',JSIdentifier 'z',JSDecimal '2'),JSSemicolon,JSIdentifier 'a'])")

    , testCase "min_100_animals1" (testProg "function Animal(name){if(!name)throw new Error('Must specify an animal name');this.name=name};Animal.prototype.toString=function(){return this.name};o=new Animal(\"bob\");o.toString()==\"bob\""
                                    "Right (JSSourceElementsTop [JSFunction \"Animal\" (JSIdentifier 'name') (JSStatementBlock [JSIf (JSUnaryExpression (\"!\",JSIdentifier 'name')) (JSThrow (JSMemberNew (JSIdentifier 'Error',JSArguments (JSStringLiteralS 'Must specify an animal name')))),JSOpAssign ('=',JSMemberDot (JSLiteral 'this',JSIdentifier 'name'),JSIdentifier 'name')]),JSOpAssign ('=',JSMemberDot (JSMemberDot (JSIdentifier 'Animal',JSIdentifier 'prototype'),JSIdentifier 'toString'),JSFunctionExpression \"\" () (JSStatementBlock [JSReturn JSMemberDot (JSLiteral 'this',JSIdentifier 'name') ]))),JSSemicolon,JSOpAssign ('=',JSIdentifier 'o',JSMemberNew (JSIdentifier 'Animal',JSArguments (JSStringLiteralD 'bob'))),JSSemicolon,JSExpressionBinary (\"==\",JSMemberExpression (JSMemberDot (JSIdentifier 'o',JSIdentifier 'toString'),JSArguments ()),JSStringLiteralD 'bob')])")

    , testCase "min_100_animals2" (testProg "Animal=function(){return this.name};" "Right (JSSourceElementsTop [JSOpAssign ('=',JSIdentifier 'Animal',JSFunctionExpression \"\" () (JSStatementBlock [JSReturn JSMemberDot (JSLiteral 'this',JSIdentifier 'name') ]))),JSSemicolon])")

    , testCase "min_100_animals3" (testProg "if(a)x=1;y=2" "Right (JSSourceElementsTop [JSIf (JSIdentifier 'a') (JSOpAssign ('=',JSIdentifier 'x',JSDecimal '1'),JSSemicolon),JSOpAssign ('=',JSIdentifier 'y',JSDecimal '2')])")

    , testCase "min_100_animals4" (testProg "if(a)x=a()y=2" "Right (JSSourceElementsTop [JSIf (JSIdentifier 'a') (JSOpAssign ('=',JSIdentifier 'x',JSMemberExpression (JSIdentifier 'a',JSArguments ()))),JSOpAssign ('=',JSIdentifier 'y',JSDecimal '2')])")

    , testCase "05_regex"  (testProg "newlines=spaces.match(/\\n/g)" "Right (JSSourceElementsTop [JSOpAssign ('=',JSIdentifier 'newlines',JSMemberExpression (JSMemberDot (JSIdentifier 'spaces',JSIdentifier 'match'),JSArguments (JSRegEx \"/\\\\n/g\")))])")

    , testCase "05_regex2" (testProg "x=/\\n/g" "Right (JSSourceElementsTop [JSOpAssign ('=',JSIdentifier 'x',JSRegEx \"/\\\\n/g\")])")

    , testCase "05_regex3" (testProg "x=i(/[?|^&(){}\\[\\]+\\-*\\/\\.]/g,\"\\\\$&\")" "Right (JSSourceElementsTop [JSOpAssign ('=',JSIdentifier 'x',JSMemberExpression (JSIdentifier 'i',JSArguments (JSRegEx \"/[?|^&(){}\\\\[\\\\]+\\\\-*\\\\/\\\\.]/g\",JSStringLiteralD '\\\\$&')))])")

    , testCase "05_regex4" (testProg "x=i(/^$/g,\"\\\\$&\")" "Right (JSSourceElementsTop [JSOpAssign ('=',JSIdentifier 'x',JSMemberExpression (JSIdentifier 'i',JSArguments (JSRegEx \"/^$/g\",JSStringLiteralD '\\\\$&')))])")

    , testCase "05_regex5" (testProg "if(/^[a-z]/.test(t)){consts+=t.toUpperCase();keywords[t]=i}else consts+=(/^\\W/.test(t)?opTypeNames[t]:t);"
                                "Right (JSSourceElementsTop [JSIf (JSMemberExpression (JSMemberDot (JSRegEx \"/^[a-z]/\",JSIdentifier 'test'),JSArguments (JSIdentifier 't'))) (JSStatementBlock [JSOpAssign ('+=',JSIdentifier 'consts',JSMemberExpression (JSMemberDot (JSIdentifier 't',JSIdentifier 'toUpperCase'),JSArguments ())),JSSemicolon,JSOpAssign ('=',JSMemberSquare (JSIdentifier 'keywords',JSIdentifier 't'),JSIdentifier 'i')]) (JSOpAssign ('+=',JSIdentifier 'consts',JSExpressionParen (JSExpressionTernary (JSMemberExpression (JSMemberDot (JSRegEx \"/^\\\\W/\",JSIdentifier 'test'),JSArguments (JSIdentifier 't')),JSMemberSquare (JSIdentifier 'opTypeNames',JSIdentifier 't'),JSIdentifier 't'))),JSSemicolon)])")

    , testCase "if_semi" (testProg "if(x);x=1"     "Right (JSSourceElementsTop [JSIf (JSIdentifier 'x') (),JSOpAssign ('=',JSIdentifier 'x',JSDecimal '1')])")

    , testCase "67_bob" (testProg "(match = /^\"(?:\\\\.|[^\"])*\"|^'(?:[^']|\\\\.)*'/(input))" "Right (JSSourceElementsTop [JSExpressionParen (JSOpAssign ('=',JSIdentifier 'match',JSMemberExpression (JSRegEx \"/^\\\"(?:\\\\\\\\.|[^\\\"])*\\\"|^'(?:[^']|\\\\\\\\.)*'/\",JSArguments (JSIdentifier 'input'))))])")

    , testCase "122_jsexec" (testProg "v = getValue(execute(n[0], x)) in getValue(execute(n[1], x));"   "Right (JSSourceElementsTop [JSOpAssign ('=',JSIdentifier 'v',JSExpressionBinary (\" in \",JSMemberExpression (JSIdentifier 'getValue',JSArguments (JSMemberExpression (JSIdentifier 'execute',JSArguments (JSMemberSquare (JSIdentifier 'n',JSDecimal '0'),JSIdentifier 'x')))),JSMemberExpression (JSIdentifier 'getValue',JSArguments (JSMemberExpression (JSIdentifier 'execute',JSArguments (JSMemberSquare (JSIdentifier 'n',JSDecimal '1'),JSIdentifier 'x')))))),JSSemicolon])")

    , testCase "bug1a" (testProg "/* */\nfunction f() {\n/*  */\n}\n" "Right (JSSourceElementsTop [JSFunction \"f\" () (JSStatementBlock [])])")
    , testCase "bug1b" (testProg "/* **/\nfunction f() {\n/*  */\n}\n" "Right (JSSourceElementsTop [JSFunction \"f\" () (JSStatementBlock [])])")

    , testCase "unicode1-ws" (testProg "a \f\v\t\r\n=\x00a0\x1680\x180e\x2000\x2001\x2002\x2003\x2004\x2005\x2006\x2007\x2008\x2009\x200a\x2028\x2029\x202f\x205f\x3000\&1;" "Right (JSSourceElementsTop [JSOpAssign ('=',JSIdentifier 'a',JSDecimal '1'),JSSemicolon])")

    , testCase "unicode2-lt" (testProg "//comment\x000Ax=1;" "Right (JSSourceElementsTop [JSOpAssign ('=',JSIdentifier 'x',JSDecimal '1'),JSSemicolon])")
    , testCase "unicode3-lt" (testProg "//comment\x000Dx=1;" "Right (JSSourceElementsTop [JSOpAssign ('=',JSIdentifier 'x',JSDecimal '1'),JSSemicolon])")
    , testCase "unicode4-lt" (testProg "//comment\x2028x=1;" "Right (JSSourceElementsTop [JSOpAssign ('=',JSIdentifier 'x',JSDecimal '1'),JSSemicolon])")
    , testCase "unicode5-lt" (testProg "//comment\x2029x=1;" "Right (JSSourceElementsTop [JSOpAssign ('=',JSIdentifier 'x',JSDecimal '1'),JSSemicolon])")

    , testCase "unicode2" (testProg "àáâãäå = 1;" "Right (JSSourceElementsTop [JSOpAssign ('=',JSIdentifier '\224\225\226\227\228\229',JSDecimal '1'),JSSemicolon])")

    , testCase "unicode3" (testProg "$aà = 1;_b=2;\0065a=2"  "Right (JSSourceElementsTop [JSOpAssign ('=',JSIdentifier '$a\224',JSDecimal '1'),JSSemicolon,JSOpAssign ('=',JSIdentifier '_b',JSDecimal '2'),JSSemicolon,JSOpAssign ('=',JSIdentifier 'Aa',JSDecimal '2')])")

    , testCase "unicode4" (testProg "x=\"àáâãäå\";y='\3012a\0068'" "Right (JSSourceElementsTop [JSOpAssign ('=',JSIdentifier 'x',JSStringLiteralD '\224\225\226\227\228\229'),JSSemicolon,JSOpAssign ('=',JSIdentifier 'y',JSStringLiteralS '\3012aD')])")

    , testCase "unicode5f" (testFileUtf8 "./test/Unicode.js" "JSSourceElementsTop [JSOpAssign ('=',JSIdentifier '\224\225\226\227\228\229',JSDecimal '1'),JSSemicolon]")

    , testCase "bug2.a" (testProg "function() {\nz = function /*z*/(o) {\nreturn r;\n};}" "Right (JSSourceElementsTop [JSFunctionExpression \"\" () (JSStatementBlock [JSOpAssign ('=',JSIdentifier 'z',JSFunctionExpression \"\" (JSIdentifier 'o') (JSStatementBlock [JSReturn JSIdentifier 'r' JSSemicolon]))),JSSemicolon]))])")

    , testCase "bug2.b" (testProg "function() {\nz = function z(o) {\nreturn r;\n};}" "Right (JSSourceElementsTop [JSFunctionExpression \"\" () (JSStatementBlock [JSOpAssign ('=',JSIdentifier 'z',JSFunctionExpression \"z\" (JSIdentifier 'o') (JSStatementBlock [JSReturn JSIdentifier 'r' JSSemicolon]))),JSSemicolon]))])")

    -- https://github.com/alanz/hjsmin/issues/#issue/3
    , testCase "bug3" (testProg "var myLatlng = new google.maps.LatLng(56.8379100, 60.5806664);" "Right (JSSourceElementsTop [JSVariable var [JSVarDecl (JSIdentifier 'myLatlng') [JSMemberNew (JSMemberDot (JSMemberDot (JSIdentifier 'google',JSIdentifier 'maps'),JSIdentifier 'LatLng'),JSArguments (JSDecimal '56.8379100',JSDecimal '60.5806664'))]]])")

    -- https://github.com/alanz/hjsmin/issues/#issue/4
    , testCase "bug4" (testProg "/* * geolocation. пытаемся определить свое местоположение * если не получается то используем defaultLocation * @Param {object} map экземпляр карты * @Param {object LatLng} defaultLocation Координаты центра по умолчанию * @Param {function} callbackAfterLocation Фу-ия которая вызывается после * геолокации. Т.к запрос геолокации асинхронен */x" "Right (JSSourceElementsTop [JSIdentifier 'x'])")

    , testCase "02_sm.js"   (testProg "{zero}\none1;two\n{three\nfour;five;\n{\nsix;{seven;}\n}\n}" "Right (JSSourceElementsTop [JSStatementBlock [JSIdentifier 'zero'],JSIdentifier 'one1',JSSemicolon,JSIdentifier 'two',JSStatementBlock [JSIdentifier 'three',JSIdentifier 'four',JSSemicolon,JSIdentifier 'five',JSSemicolon,JSStatementBlock [JSIdentifier 'six',JSSemicolon,JSStatementBlock [JSIdentifier 'seven',JSSemicolon]]]])")

    , testCase "02_sm.js.2" (testProg "{zero}\nget;two\n{three\nfour;set;\n{\nsix;{seven;}\n}\n}" "Right (JSSourceElementsTop [JSStatementBlock [JSIdentifier 'zero'],JSIdentifier 'get',JSSemicolon,JSIdentifier 'two',JSStatementBlock [JSIdentifier 'three',JSIdentifier 'four',JSSemicolon,JSIdentifier 'set',JSSemicolon,JSStatementBlock [JSIdentifier 'six',JSSemicolon,JSStatementBlock [JSIdentifier 'seven',JSSemicolon]]]])")

    , testCase "loc1" (testProg "x = 1\n  y=2;" "Right (JSSourceElementsTop [JSOpAssign ('=',JSIdentifier 'x',JSDecimal '1'),JSOpAssign ('=',JSIdentifier 'y',JSDecimal '2'),JSSemicolon])")

    -- https://github.com/alanz/language-javascript/issues/2
    , testCase "issue2" (testProg "var img=document.createElement('img');\nimg.src=\"mylogo.jpg\";\n$(img).click(function() {\nalert('clicked!');\n});" "Right (JSSourceElementsTop [JSVariable var [JSVarDecl (JSIdentifier 'img') [JSMemberExpression (JSMemberDot (JSIdentifier 'document',JSIdentifier 'createElement'),JSArguments (JSStringLiteralS 'img'))]],JSOpAssign ('=',JSMemberDot (JSIdentifier 'img',JSIdentifier 'src'),JSStringLiteralD 'mylogo.jpg'),JSSemicolon,JSCallExpression (JSCallExpressionDot (JSMemberExpression (JSIdentifier '$',JSArguments (JSIdentifier 'img')),JSIdentifier 'click'),JSArguments (JSFunctionExpression \"\" () (JSStatementBlock [JSMemberExpression (JSIdentifier 'alert',JSArguments (JSStringLiteralS 'clicked!')),JSSemicolon])))),JSSemicolon])")

    -- Working in ECMASCRIPT 5.1 changes
    , testCase "lineTerminatorInString1" (testProg "x='abc\\\ndef';"       "Right (JSSourceElementsTop [JSOpAssign ('=',JSIdentifier 'x',JSStringLiteralS 'abc\\\ndef'),JSSemicolon])")
    , testCase "lineTerminatorInString2" (testProg "x=\"abc\\\ndef\";"     "Right (JSSourceElementsTop [JSOpAssign ('=',JSIdentifier 'x',JSStringLiteralD 'abc\\\ndef'),JSSemicolon])")
    , testCase "lineTerminatorInString3" (testProg "x=\"abc\\\rdef\";"     "Right (JSSourceElementsTop [JSOpAssign ('=',JSIdentifier 'x',JSStringLiteralD 'abc\\\rdef'),JSSemicolon])")
    , testCase "lineTerminatorInString4" (testProg "x=\"abc\\\x2028 def\";"    "Right (JSSourceElementsTop [JSOpAssign ('=',JSIdentifier 'x',JSStringLiteralD 'abc\\\8232 def'),JSSemicolon])")
    , testCase "lineTerminatorInString5" (testProg "x=\"abc\\\x2029 def\";"    "Right (JSSourceElementsTop [JSOpAssign ('=',JSIdentifier 'x',JSStringLiteralD 'abc\\\8233 def'),JSSemicolon])")
    , testCase "lineTerminatorInString6" (testProg "x=\"abc\\\r\ndef\";"   "Right (JSSourceElementsTop [JSOpAssign ('=',JSIdentifier 'x',JSStringLiteralD 'abc\\\r\ndef'),JSSemicolon])")

    -- https://github.com/alanz/language-javascript/issues/4
    , testCase "issue4ok"   (testProg "var k = {\ny: somename\n}"  "Right (JSSourceElementsTop [JSVariable var [JSVarDecl (JSIdentifier 'k') [JSObjectLiteral [JSPropertyNameandValue (JSIdentifier 'y') [JSIdentifier 'somename']]]]])")
    , testCase "issue4bug1" (testProg "var k = {\ny: code\n}"      "Right (JSSourceElementsTop [JSVariable var [JSVarDecl (JSIdentifier 'k') [JSObjectLiteral [JSPropertyNameandValue (JSIdentifier 'y') [JSIdentifier 'code']]]]])")
    , testCase "issue4bug2" (testProg "var k = {\ny: mode\n}"      "Right (JSSourceElementsTop [JSVariable var [JSVarDecl (JSIdentifier 'k') [JSObjectLiteral [JSPropertyNameandValue (JSIdentifier 'y') [JSIdentifier 'mode']]]]])")

    -- https://github.com/alanz/language-javascript/issues/5
    , testCase "issue5bug1" (testProg "x = { y: 1e8 }" "Right (JSSourceElementsTop [JSOpAssign ('=',JSIdentifier 'x',JSObjectLiteral [JSPropertyNameandValue (JSIdentifier 'y') [JSDecimal '1e8']])])")
    , testCase "issue5ok2" (testProg "{ y: 1e8 }"      "Right (JSSourceElementsTop [JSStatementBlock [JSLabelled (JSIdentifier 'y') (JSDecimal '1e8')]])")
    , testCase "issue5ok3" (testProg "{ y: 18 }"       "Right (JSSourceElementsTop [JSStatementBlock [JSLabelled (JSIdentifier 'y') (JSDecimal '18')]])")
    , testCase "issue5ok4" (testProg "x = { y: 18 }"   "Right (JSSourceElementsTop [JSOpAssign ('=',JSIdentifier 'x',JSObjectLiteral [JSPropertyNameandValue (JSIdentifier 'y') [JSDecimal '18']])])")

    -- https://github.com/alanz/language-javascript/issues/14
    , testCase "issue14" (testProg "var z = x[i] / y;" "Right (JSSourceElementsTop [JSVariable var [JSVarDecl (JSIdentifier 'z') [JSExpressionBinary (\"/\",JSMemberSquare (JSIdentifier 'x',JSIdentifier 'i'),JSIdentifier 'y')]]])")

    , testCase "AutoSemiBreak"     (testProg "if(true)break \nfoo();"       "Right (JSSourceElementsTop [JSIf (JSLiteral 'true') (JSBreak),JSMemberExpression (JSIdentifier 'foo',JSArguments ()),JSSemicolon])")
    , testCase "AutoSemiContinue"  (testProg "if(true)continue \nfoo();"    "Right (JSSourceElementsTop [JSIf (JSLiteral 'true') (JSContinue),JSMemberExpression (JSIdentifier 'foo',JSArguments ()),JSSemicolon])")
    , testCase "AutoSemiReturn"    (testProg "if(true)break \nfoo();"       "Right (JSSourceElementsTop [JSIf (JSLiteral 'true') (JSBreak),JSMemberExpression (JSIdentifier 'foo',JSArguments ()),JSSemicolon])")

    , testCase "BreakBlock"       (testProg "{break}"      "Right (JSSourceElementsTop [JSStatementBlock [JSBreak]])")
    , testCase "ContinueBlock"    (testProg "{continue}"   "Right (JSSourceElementsTop [JSStatementBlock [JSContinue]])")
    , testCase "ReturnBlock"      (testProg "{return}"     "Right (JSSourceElementsTop [JSStatementBlock [JSReturn ]])")
    ]

caseHelloWorld :: Assertion
caseHelloWorld = "JSSourceElementsTop [JSIdentifier 'Hello']" @=? showStripped (readJs "Hello")

-- ---------------------------------------------------------------------

commentPrintSuite :: Test
commentPrintSuite = testGroup "Comments"
    [ testCase "Multi-comment"     (testRoundTrip "/*a*/\n//foo\nnull")

    , testCase "LiteralNull"       (testRoundTrip "/*a*/null")
    , testCase "LiteralFalse"      (testRoundTrip "/*b*/false")
    , testCase "LiteralTrue"       (testRoundTrip "true")
    , testCase "LiteralTrue"       (testRoundTrip "/*c*/true")

    , testCase "LiteralHexInteger" (testRoundTrip "/*d*/0x1234fF")
    , testCase "LiteralDecimal"    (testRoundTrip "/*e*/1.0e4")
    , testCase "LiteralOctal"      (testRoundTrip "/*x*/011")
    , testCase "LiteralString1"    (testRoundTrip "/*f*/\"hello\\nworld\"")
    , testCase "LiteralString2"    (testRoundTrip "/*g*/'hello\\nworld'")


    , testCase "LiteralThis"       (testRoundTrip "/*h*/this")

    , testCase "LiteralRegex1"     (testRoundTrip "/*i*//blah/")

    , testCase "Identifier2"       (testRoundTrip "//j\nthis_")

    , testCase "ArrayLiteral1"     (testRoundTrip "/*a*/[/*b*/]")
    , testCase "ArrayLiteral2"     (testRoundTrip "/*a*/[/*b*/,/*c*/]")
    , testCase "ArrayLiteral3"     (testRoundTrip "/*a*/[/*b*/,/*c*/,/*d*/]")
    , testCase "ArrayLiteral4"     (testRoundTrip "/*a*/[/*b/*,/*c*/,/*d*/x/*e*/]")
    , testCase "ArrayLiteral5"     (testRoundTrip "/*a*/[/*b*/,/*c*/,/*d*/x/*e*/]")
    , testCase "ArrayLiteral6"     (testRoundTrip "/*a*/[/*b*/,/*c*/x/*d*/,/*e*/,/*f*/x/*g*/]")
    , testCase "ArrayLiteral7"     (testRoundTrip "/*a*/[/*b*/x/*c*/]")
    , testCase "ArrayLiteral8"     (testRoundTrip "/*a*/[/*b*/x/*c*/,/*d*/]")

    , testCase "ObjectLiteral1"    (testRoundTrip "/*a*/{/*b*/}")
    , testCase "ObjectLiteral2"    (testRoundTrip "/*a*/{/*b*/x/*c*/:/*d*/1/*e*/}")
    , testCase "ObjectLiteral3"    (testRoundTrip "x=/*a*/{/*b*/x/*c*/:/*d*/1/*e*/,/*f*/y/*g*/:/*h*/2/*i*/}")
    , testCase "ObjectLiteral3a"   (testRoundTrip "x=/*a*/{/*b*/x/*c*/:/*d*/1/*e*/,/*f*/y/*g*/:/*h*/2/*i*/,/*j*/z/*k*/:/*l*/3/*m*/}")

    , testCase "ObjectLiteral5"    (testRoundTrip "a=/*a*/{/*b*/x/*c*/:/*d*/1/*e*/,/*f*/}")

    -- Edition 5 extensions
    , testCase "ObjectLiteral7"    (testRoundTrip "/*a*/x/*b*/=/*c*/{/*d*/get/*e*/ foo/*f*/(/*g*/)/*h*/ {/*i*/return/*j*/ 1/*k*/}/*l*/,/*m*/set/*n*/ foo/*o*/(/*p*/a/*q*/) /*r*/{/*s*/x/*t*/=/*u*/a/*v*/}/*w*/}")

    , testCase "ExpressionParen"   (testRoundTrip "/*a*/(/*b*/56/*c*/)")

    , testCase "Statement1"        (testRoundTrip "/*a*/x")

    , testCase "Statement2"        (testRoundTrip "/*a*/null")

    , testCase "Statement3"        (testRoundTrip "/*a*/true/*b*/?/*c*/1/*d*/:/*e*/2")

    , testCase "Statement4"        (testRoundTrip "/*a*/x/*b*/||/*c*/y")

    , testCase "Statement5"        (testRoundTrip "/*a*/x/*b*/&&/*c*/y")

    , testCase "Statement6a"       (testRoundTrip "/*a*/x/*b*/|/*c*/y")

    , testCase "Statement6b"       (testRoundTrip "/*a*/x/*b*/^/*c*/y")

    , testCase "Statement7"        (testRoundTrip "/*a*/x/*b*/&/*c*/y")

    , testCase "Statement8"        (testRoundTrip "/*a*/x/*b*/==/*c*/y")

    , testCase "Statement9"        (testRoundTrip "/*a*/x/*b*/!=/*c*/y")

    , testCase "Statement10"       (testRoundTrip "/*a*/x/*b*/===/*c*/y")

    , testCase "Statement11"       (testRoundTrip "/*a*/x/*b*/!==/*c*/y")

    , testCase "Statement12a"      (testRoundTrip "/*a*/x/*b*/</*c*/y")

    , testCase "Statement12b"      (testRoundTrip "/*a*/x/*b*/>/*c*/y")

    , testCase "Statement12c"      (testRoundTrip "/*a*/x/*b*/<=/*c*/y")

    , testCase "Statement12d"      (testRoundTrip "/*a*/x/*b*/>=/*c*/y")

    , testCase "Statement12e"      (testRoundTrip "/*a*/x /*b*/instanceof /*c*/y")



    , testCase "Statement13"       (testRoundTrip "x<<y")
    , testCase "Statement13"       (testRoundTrip "x>>y")
    , testCase "Statement13"       (testRoundTrip "x>>>y")

    , testCase "Statement14"       (testRoundTrip "x+y")
    , testCase "Statement14"       (testRoundTrip "x-y")

    , testCase "Statement15"       (testRoundTrip "x*y")
    , testCase "Statement16"       (testRoundTrip "x/y")
    , testCase "Statement17"       (testRoundTrip "x%y")

    , testCase "Statement18"       (testRoundTrip "delete y")
    , testCase "Statement19"       (testRoundTrip "void y")
    , testCase "Statement20"       (testRoundTrip "typeof y")
    , testCase "Statement21"       (testRoundTrip "++y")
    , testCase "Statement22"       (testRoundTrip "--y")
    , testCase "Statement23"       (testRoundTrip "+y")
    , testCase "Statement24"       (testRoundTrip "-y")
    , testCase "Statement25"       (testRoundTrip "~y")
    , testCase "Statement26"       (testRoundTrip "!y")

    , testCase "Statement27"       (testRoundTrip "y++")
    , testCase "Statement28"       (testRoundTrip "y--")

      -- Member Expressions
    , testCase "MemberExpression1a" (testRoundTrip "function(){}")
    , testCase "MemberExpression1b" (testRoundTrip "function(a){}")
    , testCase "MemberExpression1c" (testRoundTrip "function(a,b){}")

    , testCase "MemberExpression1d" (testRoundTrip "x[y]")
    , testCase "MemberExpression1e" (testRoundTrip "x[y][z]")
    , testCase "MemberExpression1f" (testRoundTrip "x.y")
    , testCase "MemberExpression1g" (testRoundTrip "x.y.z")

    , testCase "MemberExpression1h" (testRoundTrip "new x()")

    , testCase "NewExpression1" (testRoundTrip "new x.y")

    , testCase "CallExpression1" (testRoundTrip "x()")
    , testCase "CallExpression2" (testRoundTrip "x()()")
    , testCase "CallExpression3" (testRoundTrip "x()[4]")
    , testCase "CallExpression4" (testRoundTrip "x().x")
    , testCase "CallExpression5" (testRoundTrip "x(a,b=2).x")

    , testCase "AssignExpression1" (testRoundTrip "x=1")
    , testCase "AssignExpression1" (testRoundTrip "x*=1")
    , testCase "AssignExpression1" (testRoundTrip "x/=1")
    , testCase "AssignExpression1" (testRoundTrip "x%=1")
    , testCase "AssignExpression1" (testRoundTrip "x+=1")
    , testCase "AssignExpression1" (testRoundTrip "x-=1")
    , testCase "AssignExpression1" (testRoundTrip "x<<=1")
    , testCase "AssignExpression1" (testRoundTrip "x>>=1")
    , testCase "AssignExpression1" (testRoundTrip "x>>>=1")
    , testCase "AssignExpression1" (testRoundTrip "x&=1")
    , testCase "AssignExpression1" (testRoundTrip "x^=1")
    , testCase "AssignExpression1" (testRoundTrip "x|=1")


    , testCase "Block1" (testRoundTrip "{}")
    , testCase "Block2" (testRoundTrip "{x=1}")
    , testCase "Block3" (testRoundTrip "{x=1;y=2}")
    , testCase "Block4" (testRoundTrip "{{}}")
    , testCase "Block5" (testRoundTrip "{{{}}}")


    , testCase "If1" (testRoundTrip "if (1) {}")

    , testCase "IfElse1" (testRoundTrip "if (1) {} else {}")
    , testCase "IfElse2" (testRoundTrip "if (1) x=1; else {}")

    , testCase "DoWhile1" (testRoundTrip "do {x=1} while (true);")
    , testCase "While1"   (testRoundTrip "while(true);")

    , testCase "For1"   (testRoundTrip "for(;;);")
    , testCase "For2"   (testRoundTrip "for(x=1;x<10;x++);")

    , testCase "ForVar1"   (testRoundTrip "for(var x;;);")
    , testCase "ForVar2"   (testRoundTrip "for(var x=1;;);")
    , testCase "ForVar2"   (testRoundTrip "for(var x;y;z){}")

    , testCase "ForIn1"   (testRoundTrip "for(x in 5){}")

    , testCase "ForVarIn1" (testRoundTrip "for(var x in 5){}")

    , testCase "Var1" (testRoundTrip "var x=1;")
    , testCase "Var2" (testRoundTrip "const x=1,y=2;")


    , testCase "Continue1" (testRoundTrip "continue;")
    , testCase "Continue2" (testRoundTrip "continue x;")

    , testCase "Break1" (testRoundTrip "break;")
    , testCase "Break2" (testRoundTrip "break x;")

    , testCase "Return1" (testRoundTrip "return;")
    , testCase "Return2" (testRoundTrip "return x;")

    , testCase "With1" (testRoundTrip "with (x) {};")

    , testCase "Labelled1" (testRoundTrip "abc:x=1")

    , testCase "Switch1" (testRoundTrip "switch (x) {}")
    , testCase "Switch2" (testRoundTrip "switch (x) {case 1:break;}")
    , testCase "Switch3" (testRoundTrip "switch (x) {case 0:\ncase 1:break;}")
    , testCase "Switch4" (testRoundTrip "switch (x) {default:break;}")
    , testCase "Switch5" (testRoundTrip "switch (x) {default:\ncase 1:break;}")

    , testCase "Throw1" (testRoundTrip "throw 1")

    , testCase "Try1" (testRoundTrip "try{}catch(a){}")
    , testCase "Try2" (testRoundTrip "try{}finally{}")
    , testCase "Try3" (testRoundTrip "try{}catch(a){}finally{}")

    , testCase "Try4" (testRoundTrip "try{}catch(a){}catch(b){}finally{}")
    , testCase "Try5" (testRoundTrip "try{}catch(a){}catch(b){}")
    , testCase "Try6" (testRoundTrip "try{}catch(a if true){}catch(b){}")

    , testCase "Function1" (testRoundTrip "function a(){}")
    , testCase "Function2" (testRoundTrip "function a(b,c){}")


    , testCase "Comment1" (testRoundTrip "//blah\nx=1;//foo\na")

    , testCase "Comment2" (testRoundTrip "/*x=1\ny=2\n*/z=2;//foo\na")

    , testCase "min_100_animals1" (testRoundTrip "function Animal(name){if(!name)throw new Error('Must specify an animal name');this.name=name};Animal.prototype.toString=function(){return this.name};o=new Animal(\"bob\");o.toString()==\"bob\"")

    , testCase "min_100_animals2" (testRoundTrip "Animal=function(){return this.name};")

    , testCase "min_100_animals3" (testRoundTrip "if(a)x=1;y=2")

    , testCase "min_100_animals4" (testRoundTrip "if(a)x=a()y=2")

    , testCase "05_regex"  (testRoundTrip "newlines=spaces.match(/\\n/g)")

    , testCase "05_regex2" (testRoundTrip "x=/\\n/g")

    , testCase "05_regex3" (testRoundTrip "x=i(/[?|^&(){}\\[\\]+\\-*\\/\\.]/g,\"\\\\$&\")")

    , testCase "05_regex4" (testRoundTrip "x=i(/^$/g,\"\\\\$&\")")

    , testCase "05_regex5" (testRoundTrip "if(/^[a-z]/.test(t)){consts+=t.toUpperCase();keywords[t]=i}else consts+=(/^\\W/.test(t)?opTypeNames[t]:t);")

    , testCase "if_semi" (testRoundTrip "if(x);x=1")

    , testCase "67_bob" (testRoundTrip "(match = /^\"(?:\\\\.|[^\"])*\"|^'(?:[^']|\\\\.)*'/(input))")

    , testCase "122_jsexec" (testRoundTrip "v = getValue(execute(n[0], x)) in getValue(execute(n[1], x));")

    , testCase "bug1a" (testRoundTrip "/* */\nfunction f() {\n/*  */\n}")
    , testCase "bug1b" (testRoundTrip "/* **/\nfunction f() {\n/*  */\n}")

    , testCase "unicode1-ws" (testRoundTrip "a \f\v\t\r\n=\x00a0\x1680\x180e\x2000\x2001\x2002\x2003\x2004\x2005\x2006\x2007\x2008\x2009\x200a\x2028\x2029\x202f\x205f\x3000\&1;")

    , testCase "unicode2-lt" (testRoundTrip "//comment\x000Ax=1;")
    , testCase "unicode3-lt" (testRoundTrip "//comment\x000Dx=1;")
    , testCase "unicode4-lt" (testRoundTrip "//comment\x2028x=1;")
    , testCase "unicode5-lt" (testRoundTrip "//comment\x2029x=1;")

    , testCase "unicode2" (testRoundTrip "àáâãäå = 1;")

    , testCase "unicode3" (testRoundTrip "$aà = 1;_b=2;\0065a=2")

    , testCase "unicode4" (testRoundTrip "x=\"àáâãäå\";y='\3012a\0068'")

    -- , testCase "unicode5" (testFile "./test/Unicode.js")

    , testCase "bug2.a" (testRoundTrip "function() {\nz = function /*z*/(o) {\nreturn r;\n};}")

    , testCase "bug2.b" (testRoundTrip "function() {\nz = function z(o) {\nreturn r;\n};}")

    -- https://github.com/alanz/hjsmin/issues/#issue/3
    , testCase "bug3" (testRoundTrip "var myLatlng = new google.maps.LatLng(56.8379100, 60.5806664);")

    -- https://github.com/alanz/hjsmin/issues/#issue/4
    , testCase "bug4" (testRoundTrip "/* * geolocation. пытаемся определить свое местоположение * если не получается то используем defaultLocation * @Param {object} map экземпляр карты * @Param {object LatLng} defaultLocation Координаты центра по умолчанию * @Param {function} callbackAfterLocation Фу-ия которая вызывается после * геолокации. Т.к запрос геолокации асинхронен */x")

    , testCase "02_sm.js"   (testRoundTrip "{zero}\none1;two\n{three\nfour;five;\n{\nsix;{seven;}\n}\n}")

    , testCase "02_sm.js.2" (testRoundTrip "{zero}\nget;two\n{three\nfour;set;\n{\nsix;{seven;}\n}\n}")

    , testCase "loc1" (testRoundTrip "x = 1\n  y=2;")

    -- https://github.com/alanz/language-javascript/issues/2
    , testCase "issue2" (testRoundTrip "var img = document.createElement('img');\nimg.src = \"mylogo.jpg\";\n$(img).click(function() {\n   alert('clicked!');\n});")


    -- Working in ECMASCRIPT 5.1 changes
    , testCase "lineTerminatorInString1" (testRoundTrip "x='abc\\\ndef';")
    , testCase "lineTerminatorInString2" (testRoundTrip "x=\"abc\\\ndef\";")
    , testCase "lineTerminatorInString3" (testRoundTrip "x=\"abc\\\rdef\";")
    , testCase "lineTerminatorInString4" (testRoundTrip "x=\"abc\\\x2028 def\";")
    , testCase "lineTerminatorInString5" (testRoundTrip "x=\"abc\\\x2029 def\";")
    , testCase "lineTerminatorInString6" (testRoundTrip "x=\"abc\\\r\ndef\";")


    -- https://github.com/alanz/language-javascript/issues/4
    , testCase "issue4ok"   (testRoundTrip "var k = {\ny: somename\n}")
    , testCase "issue4bug1" (testRoundTrip "var k = {\ny: code\n}")
    , testCase "issue4bug2" (testRoundTrip "var k = {\ny: mode\n}")

    -- https://github.com/alanz/language-javascript/issues/5
    , testCase "issue5bug1" (testRoundTrip "x = { y: 1e8 }")
    , testCase "issue5ok2" (testRoundTrip "{ y: 1e8 }")
    , testCase "issue5ok3" (testRoundTrip "{ y: 18 }")
    , testCase "issue5ok4" (testRoundTrip "x = { y: 18 }")

    -- function body
    , testCase "functionbody"       (testRoundTrip "function foo(a,b,c)\n{x=1;}")
    , testCase "functionexpression" (testRoundTrip "function foo(a,b,c)\n{x=1;}")

    , testCase "fn1" (testRoundTrip "function foo() { return 5; }")
    , testCase "fn2" (testRoundTrip "var foo = function() { return 5; }")
    , testCase "fn3" (testRoundTrip "var foo = function foo() { return 5; }")

    -- Parse failure in hjsmin
    , testCase "parsefail" (testRoundTrip "switch(t){case DIV:         v = u / v; break;}")

    -- https://github.com/alanz/language-javascript/issues/14
    , testCase "issue14" (testRoundTrip "var z = x[i] / y;")

    -- https://github.com/alanz/language-javascript/issues/15
    , testCase "issue15" (testRoundTrip "x\t=1;")

    , testCase "comment-only" (testRoundTrip "// comment\n\n")
    , testCase "empty-src" (testRoundTrip "")
    ]

-- ---------------------------------------------------------------------
-- Test utilities

testRoundTrip :: String -> Assertion
testRoundTrip str = str @=? renderToString (readJs str)

testLiteral :: String -> String -> Assertion
testLiteral literal expected = expected @=? showStrippedMaybe (parseUsing parseLiteral literal "src")

testLiteralC :: String -> String -> Assertion
testLiteralC literal expected = expected @=? show (parseUsing parseLiteral literal "src")


testPE :: String -> String -> Assertion
testPE str expected = expected @=? showStrippedMaybe (parseUsing parsePrimaryExpression str "src")

testPEC :: String -> String -> Assertion
testPEC str expected = expected @=? show (parseUsing parsePrimaryExpression str "src")

testStmt :: String -> String -> Assertion
testStmt str expected = do
    expected @=? showStrippedMaybe (parseUsing parseStatement str "src")
    testRoundTrip str

testStmtC :: String -> String -> Assertion
testStmtC str expected = do
    expected @=? show (parseUsing parseStatement str "src")
    testRoundTrip str


testProg :: String -> String -> Assertion
testProg str expected = do
    expected @=? showStrippedMaybe (parseUsing parseProgram str "src")
    testRoundTrip str

testProgC :: String -> String -> Assertion
testProgC str expected = expected @=? show (parseUsing parseProgram str "src")

testProgUn :: String -> String -> Assertion
testProgUn str expected = do
    expected @=? showStrippedMaybe (parseUsing parseProgram str "src")
    testRoundTrip str


testFile :: FilePath -> String -> IO ()
testFile fileName expected = do
    res <- parseFile fileName
    expected @=? showStripped res

testFileUtf8 :: FilePath -> String -> IO ()
testFileUtf8 fileName expected = do
    res <- parseFileUtf8 fileName
    expected @=? showStripped res

testLexer :: String -> String -> Assertion
testLexer str expected =
    expected @=? either id stringify (alexTestTokeniser str)

stringify :: [Token] -> String
stringify xs = "[" ++ intercalate "," (map (takeWhile (/= ' ') . show) xs) ++ "]"
