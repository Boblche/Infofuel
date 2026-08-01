enum FuelType {
  gazole('gazole', 'Gazole'),
  sp95('sp95', 'SP95'),
  sp98('sp98', 'SP98'),
  e10('e10', 'E10'),
  e85('e85', 'E85'),
  gplc('gplc', 'GPLc');

  const FuelType(this.apiKey, this.label);

  final String apiKey;
  final String label;

  String get priceField => '${apiKey}_prix';
}
