module aodheme.peggedgrammar;
import pegged.grammar;

mixin(grammar(`
  AOQ:
    Loop < (SExpr / List / UnparsedElement)+
    SExpr < "(" (Lambda/Atom/SExpr/UnparsedElement)+ ")"

    LoopNoParen < (Lambda / SExpr / SExprNoParen / List / UnparsedElement)+
    SExprNoParen < (Lambda/Atom/SExpr/UnparsedElement)+

    Sign <- "-"
    Integer <- digit+
    IntegerL <- Sign? Integer
    FloatL <- IntegerL "." Integer "f"
    List < ("~(" ListElement* ")") / ("[" ListElement* "]")
    UnparsedElement < "~" ListElement
    Lambda < "(" "lambda" "(" LambdaArgs+ ")" "{" Loop "}" ")"
    LambdaArgs < Variable

    ListElement < (Atom / SExpr / List)

    Atom <- FloatL / IntegerL / Variable / List / Operator

    Variable <- (alpha / Alpha) (alpha / Alpha / Operator / digit)*
    Operator <- ("+" / "-" / "*" / "/" / "<" / ">" / ">=" / "<=" / "=")+
`));
