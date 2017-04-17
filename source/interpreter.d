module interpreter;
import globals, atom, environment, pegged.grammar : ParseTree;


string Eval ( string str_expression ) {
  global_environment = Construct_Default_Environment!();
  import peggedgrammar;
  auto expression = AOQ(str_expression);
  writeln("EXPR: ", expression);
  auto res = expression.Eval_Tree.To_String;
  writeln("Result: ", res);
  return res;
}



private Atom List_Eval ( ParseTree[] tree ) {
  auto List_Eval_Helper ( ParseTree elem ) {
    import std.algorithm, std.array, std.conv : to;
    switch ( elem.name ) {
      default:         return Atom(elem.matches.joiner.array.to!string);
      case "AOQ.ListElement": case "AOQ.Atom":
        return List_Eval_Helper(elem.children[0]);
      case "AOQ.List":
        return List_Eval(elem.children);
    }
  }

  Atom[] list;
  foreach ( elem; tree ) {
    list ~= List_Eval_Helper(elem);
  }
  return Atom(list);
}



Atom Eval_Tree ( ParseTree atom, Environment environment = global_environment) {
  import std.algorithm, std.array, std.conv : to;
  switch ( atom.name ) {
    default:
      assert(false, "Unknown atom name: `" ~ atom.name ~ "`");
    case "AOQ": case "AOQ.Loop":
      Atom result;
      foreach ( ref a_child; atom.children ) {
        result = a_child.Eval_Tree(environment);
      }
      return result;
    case "AOQ.Atom":
      return Eval_Tree(atom.children[0], environment);
    case "AOQ.List":
      return List_Eval(atom.children);
    case "AOQ.UnparsedElement":
      return Atom(atom.matches[1..$].joiner.array.to!string);
    case "AOQ.LambdaArgs":
      return Atom(atom.matches.joiner.array.to!string);
    case "AOQ.Variable": case "AOQ.Operator":
      return environment.Search(atom.matches[0..$].joiner.array.to!string);
    case "AOQ.IntegerL":
      return Atom(atom.matches[0..$].joiner.array.to!int);
    case "AOQ.FloatL":
      auto m = atom.matches[0..$];
      if ( m[$-1] == "f" ) m = m[0 .. $-1];
      return Atom(m.joiner.array.to!float);
    case "AOQ.Lambda":
      import functions;
      Atom[] args = atom.children[0..$-1]
                        .map!(n => Eval_Tree(n, environment))
                        .array;
      auto   func = new Function(args, atom.children[$-1]);
      return Atom(func);
    case "AOQ.SExpr":
      auto func = atom.children[0].Eval_Tree(environment);
      auto args = atom.children[1 .. $]
                      .map!(n => Eval_Tree(n, environment))
                      .array;
      writeln(func, " ", args);
      import functions;
      auto res = func.RType == typeid(Function) ?
                      Func_Call(func, args, environment) :
                      func;
      writeln("    ==> ", res);
      return res;
  }
}