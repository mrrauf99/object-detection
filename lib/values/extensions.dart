extension ListOfDoubleExtension on List<num> {
  List<int> get toIntList {
    final itemLength = length;
    return [
      for (var i = 0; i < itemLength; i++) this[i].toInt(),
    ];
  }
}
