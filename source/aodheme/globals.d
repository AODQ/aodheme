public import std.stdio;

Element* RElem_In_Bounds ( Element ) ( Element[] array, size_t index ) {
  if ( array.length <= index ) return null;
  return &array[index];
}
