// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verse.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetVerseCollection on Isar {
  IsarCollection<Verse> get verses => this.collection();
}

const VerseSchema = CollectionSchema(
  name: r'Verse',
  id: 6982547837312371642,
  properties: {
    r'book': PropertySchema(
      id: 0,
      name: r'book',
      type: IsarType.string,
    ),
    r'chapter': PropertySchema(
      id: 1,
      name: r'chapter',
      type: IsarType.long,
    ),
    r'verse': PropertySchema(
      id: 2,
      name: r'verse',
      type: IsarType.long,
    )
  },
  estimateSize: _verseEstimateSize,
  serialize: _verseSerialize,
  deserialize: _verseDeserialize,
  deserializeProp: _verseDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _verseGetId,
  getLinks: _verseGetLinks,
  attach: _verseAttach,
  version: '3.1.0+1',
);

int _verseEstimateSize(
  Verse object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.book.length * 3;
  return bytesCount;
}

void _verseSerialize(
  Verse object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.book);
  writer.writeLong(offsets[1], object.chapter);
  writer.writeLong(offsets[2], object.verse);
}

Verse _verseDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Verse();
  object.book = reader.readString(offsets[0]);
  object.chapter = reader.readLong(offsets[1]);
  object.id = id;
  object.verse = reader.readLong(offsets[2]);
  return object;
}

P _verseDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _verseGetId(Verse object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _verseGetLinks(Verse object) {
  return [];
}

void _verseAttach(IsarCollection<dynamic> col, Id id, Verse object) {
  object.id = id;
}

extension VerseQueryWhereSort on QueryBuilder<Verse, Verse, QWhere> {
  QueryBuilder<Verse, Verse, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension VerseQueryWhere on QueryBuilder<Verse, Verse, QWhereClause> {
  QueryBuilder<Verse, Verse, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Verse, Verse, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Verse, Verse, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Verse, Verse, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Verse, Verse, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension VerseQueryFilter on QueryBuilder<Verse, Verse, QFilterCondition> {
  QueryBuilder<Verse, Verse, QAfterFilterCondition> bookEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'book',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Verse, Verse, QAfterFilterCondition> bookGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'book',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Verse, Verse, QAfterFilterCondition> bookLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'book',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Verse, Verse, QAfterFilterCondition> bookBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'book',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Verse, Verse, QAfterFilterCondition> bookStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'book',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Verse, Verse, QAfterFilterCondition> bookEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'book',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Verse, Verse, QAfterFilterCondition> bookContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'book',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Verse, Verse, QAfterFilterCondition> bookMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'book',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Verse, Verse, QAfterFilterCondition> bookIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'book',
        value: '',
      ));
    });
  }

  QueryBuilder<Verse, Verse, QAfterFilterCondition> bookIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'book',
        value: '',
      ));
    });
  }

  QueryBuilder<Verse, Verse, QAfterFilterCondition> chapterEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'chapter',
        value: value,
      ));
    });
  }

  QueryBuilder<Verse, Verse, QAfterFilterCondition> chapterGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'chapter',
        value: value,
      ));
    });
  }

  QueryBuilder<Verse, Verse, QAfterFilterCondition> chapterLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'chapter',
        value: value,
      ));
    });
  }

  QueryBuilder<Verse, Verse, QAfterFilterCondition> chapterBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'chapter',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Verse, Verse, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Verse, Verse, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Verse, Verse, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Verse, Verse, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Verse, Verse, QAfterFilterCondition> verseEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'verse',
        value: value,
      ));
    });
  }

  QueryBuilder<Verse, Verse, QAfterFilterCondition> verseGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'verse',
        value: value,
      ));
    });
  }

  QueryBuilder<Verse, Verse, QAfterFilterCondition> verseLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'verse',
        value: value,
      ));
    });
  }

  QueryBuilder<Verse, Verse, QAfterFilterCondition> verseBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'verse',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension VerseQueryObject on QueryBuilder<Verse, Verse, QFilterCondition> {}

extension VerseQueryLinks on QueryBuilder<Verse, Verse, QFilterCondition> {}

extension VerseQuerySortBy on QueryBuilder<Verse, Verse, QSortBy> {
  QueryBuilder<Verse, Verse, QAfterSortBy> sortByBook() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'book', Sort.asc);
    });
  }

  QueryBuilder<Verse, Verse, QAfterSortBy> sortByBookDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'book', Sort.desc);
    });
  }

  QueryBuilder<Verse, Verse, QAfterSortBy> sortByChapter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chapter', Sort.asc);
    });
  }

  QueryBuilder<Verse, Verse, QAfterSortBy> sortByChapterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chapter', Sort.desc);
    });
  }

  QueryBuilder<Verse, Verse, QAfterSortBy> sortByVerse() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verse', Sort.asc);
    });
  }

  QueryBuilder<Verse, Verse, QAfterSortBy> sortByVerseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verse', Sort.desc);
    });
  }
}

extension VerseQuerySortThenBy on QueryBuilder<Verse, Verse, QSortThenBy> {
  QueryBuilder<Verse, Verse, QAfterSortBy> thenByBook() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'book', Sort.asc);
    });
  }

  QueryBuilder<Verse, Verse, QAfterSortBy> thenByBookDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'book', Sort.desc);
    });
  }

  QueryBuilder<Verse, Verse, QAfterSortBy> thenByChapter() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chapter', Sort.asc);
    });
  }

  QueryBuilder<Verse, Verse, QAfterSortBy> thenByChapterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'chapter', Sort.desc);
    });
  }

  QueryBuilder<Verse, Verse, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Verse, Verse, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Verse, Verse, QAfterSortBy> thenByVerse() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verse', Sort.asc);
    });
  }

  QueryBuilder<Verse, Verse, QAfterSortBy> thenByVerseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'verse', Sort.desc);
    });
  }
}

extension VerseQueryWhereDistinct on QueryBuilder<Verse, Verse, QDistinct> {
  QueryBuilder<Verse, Verse, QDistinct> distinctByBook(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'book', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Verse, Verse, QDistinct> distinctByChapter() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'chapter');
    });
  }

  QueryBuilder<Verse, Verse, QDistinct> distinctByVerse() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'verse');
    });
  }
}

extension VerseQueryProperty on QueryBuilder<Verse, Verse, QQueryProperty> {
  QueryBuilder<Verse, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Verse, String, QQueryOperations> bookProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'book');
    });
  }

  QueryBuilder<Verse, int, QQueryOperations> chapterProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'chapter');
    });
  }

  QueryBuilder<Verse, int, QQueryOperations> verseProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'verse');
    });
  }
}
