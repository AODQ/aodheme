module interpreter;
import globals, atom, environment, pegged.grammar : ParseTree;

void Initialize ( ) {
  global_environment = Construct_Default_Environment!();
}

auto Evaluate ( string expression ) {
  import peggedgrammar;
  return AOQ(expression);
}

string Eval ( string str_expression ) {
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



int tab;

string TTab ( ) {
  string t = "";
  foreach ( i; 0 .. tab ) t ~= "  ";
  return t;
}
Atom Eval_Tree ( ParseTree atom, Environment environment = global_environment) {
  import std.algorithm, std.array, std.conv : to;
  switch ( atom.name ) {
    default:
      assert(false, "Unknown atom name: `" ~ atom.name ~ "`");
    case "AOQ": case "AOQ.Loop": case "AOQ.LoopNoParen":
      Atom result;
      writeln(TTab ~ "===>");
      ++ tab;
      foreach ( i; atom.children ) {
        writeln(TTab, "CHILD: ", i.name);
      }
      foreach ( ref a_child; atom.children ) {
        writeln(TTab ~ "LOOP: ", a_child.matches.joiner);
        result = a_child.Eval_Tree(environment);
        writeln(TTab, "LOOP RES: ", result);
      }
      -- tab;
      writeln(TTab ~ "<=== ", result);
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
      writeln(TTab, " LAMBDA!");
      return Atom(func);
    case "AOQ.SExpr":
      auto func = atom.children[0].Eval_Tree(environment);
      auto args = atom.children[1 .. $]
                      .map!(n => Eval_Tree(n, environment))
                      .array;
      import functions;
      writeln(TTab, "FN: ", atom.children[0].matches.joiner);
      auto res = func.RType == typeid(Function) ?
                      Func_Call(func, args, environment) :
                      func;
      writeln(TTab, "RES: ", res);
      return res;
  }
}
