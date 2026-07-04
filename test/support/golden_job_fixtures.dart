import 'package:roofgrid_uk/models/tile_model.dart';
import 'package:roofgrid_uk/utils/tile_calculation_profile.dart'
    show parseTileSlateTypeFromString;

/// Standard site job dimensions shared by all golden fixtures.
const double kGoldenRafterHeightMm = 5000;
const double kGoldenGutterOverhangMm = 50;
const double kGoldenRoofWidthMm = 6000;

class GoldenVerticalExpectation {
  final String solution;
  final int totalCourses;
  final int eaveBatten;
  final int? underEaveBatten;
  final int ridgeOffset;
  final String gauge;

  const GoldenVerticalExpectation({
    required this.solution,
    required this.totalCourses,
    required this.eaveBatten,
    required this.underEaveBatten,
    required this.ridgeOffset,
    required this.gauge,
  });
}

class GoldenHorizontalExpectation {
  final String solution;
  final String marks;
  final int firstMark;
  final int? secondMark;
  final int actualSpacing;
  final int designWidth;
  final int adjustedWidth;
  final int? lhOverhang;
  final int? rhOverhang;

  const GoldenHorizontalExpectation({
    required this.solution,
    required this.marks,
    required this.firstMark,
    required this.secondMark,
    required this.actualSpacing,
    required this.designWidth,
    required this.adjustedWidth,
    this.lhOverhang,
    this.rhOverhang,
  });
}

class GoldenJobFixture {
  final String id;
  final String materialType;
  final double slateTileHeight;
  final double tileCoverWidth;
  final double minGauge;
  final double maxGauge;
  final double minSpacing;
  final double maxSpacing;
  final bool defaultCrossBonded;
  final GoldenVerticalExpectation vertical;
  final GoldenHorizontalExpectation horizontal;

  const GoldenJobFixture({
    required this.id,
    required this.materialType,
    required this.slateTileHeight,
    required this.tileCoverWidth,
    required this.minGauge,
    required this.maxGauge,
    required this.minSpacing,
    required this.maxSpacing,
    required this.defaultCrossBonded,
    required this.vertical,
    required this.horizontal,
  });
}

/// Pinned outputs for the standard 5000 mm rafter / 6000 mm width job.
const List<GoldenJobFixture> kGoldenJobFixtures = [
  GoldenJobFixture(
    id: 'slate',
    materialType: 'Slate',
    slateTileHeight: 500,
    tileCoverWidth: 250,
    minGauge: 195,
    maxGauge: 210,
    minSpacing: 1,
    maxSpacing: 5,
    defaultCrossBonded: true,
    vertical: GoldenVerticalExpectation(
      solution: 'Even Courses',
      totalCourses: 23,
      eaveBatten: 265,
      underEaveBatten: null,
      ridgeOffset: 37,
      gauge: '22 @ 204',
    ),
    horizontal: GoldenHorizontalExpectation(
      solution: 'Even Sets',
      marks: '7 sets of 3 @ 762',
      firstMark: 756,
      secondMark: 883,
      actualSpacing: 4,
      designWidth: 6100,
      adjustedWidth: 6096,
      lhOverhang: 48,
      rhOverhang: 48,
    ),
  ),
  GoldenJobFixture(
    id: 'plain-tile',
    materialType: 'Plain Tile',
    slateTileHeight: 265,
    tileCoverWidth: 165,
    minGauge: 85,
    maxGauge: 115,
    minSpacing: 1,
    maxSpacing: 7,
    defaultCrossBonded: true,
    vertical: GoldenVerticalExpectation(
      solution: 'Even Courses',
      totalCourses: 44,
      eaveBatten: 150,
      underEaveBatten: null,
      ridgeOffset: 27,
      gauge: '43 @ 111',
    ),
    horizontal: GoldenHorizontalExpectation(
      solution: 'Even Sets',
      marks: '11 sets of 3 @ 507',
      firstMark: 495,
      secondMark: 580,
      actualSpacing: 4,
      designWidth: 6100,
      adjustedWidth: 6084,
      lhOverhang: 42,
      rhOverhang: 42,
    ),
  ),
  GoldenJobFixture(
    id: 'interlocking-tile',
    materialType: 'Interlocking Tile',
    slateTileHeight: 420,
    tileCoverWidth: 300,
    minGauge: 310,
    maxGauge: 345,
    minSpacing: 1,
    maxSpacing: 5,
    defaultCrossBonded: false,
    vertical: GoldenVerticalExpectation(
      solution: 'Even Courses',
      totalCourses: 15,
      eaveBatten: 345,
      underEaveBatten: null,
      ridgeOffset: 35,
      gauge: '14 @ 330',
    ),
    horizontal: GoldenHorizontalExpectation(
      solution: 'Even Sets',
      marks: '9 sets of 2 @ 610',
      firstMark: 605,
      secondMark: null,
      actualSpacing: 5,
      designWidth: 6100,
      adjustedWidth: 6100,
      lhOverhang: 50,
      rhOverhang: 50,
    ),
  ),
  GoldenJobFixture(
    id: 'concrete-tile',
    materialType: 'Concrete Tile',
    slateTileHeight: 420,
    tileCoverWidth: 300,
    minGauge: 310,
    maxGauge: 345,
    minSpacing: 1,
    maxSpacing: 5,
    defaultCrossBonded: false,
    vertical: GoldenVerticalExpectation(
      solution: 'Even Courses',
      totalCourses: 15,
      eaveBatten: 345,
      underEaveBatten: null,
      ridgeOffset: 35,
      gauge: '14 @ 330',
    ),
    horizontal: GoldenHorizontalExpectation(
      solution: 'Even Sets',
      marks: '9 sets of 2 @ 610',
      firstMark: 605,
      secondMark: null,
      actualSpacing: 5,
      designWidth: 6100,
      adjustedWidth: 6100,
      lhOverhang: 50,
      rhOverhang: 50,
    ),
  ),
  GoldenJobFixture(
    id: 'fibre-cement-slate',
    materialType: 'Fibre Cement Slate',
    slateTileHeight: 600,
    tileCoverWidth: 300,
    minGauge: 235,
    maxGauge: 255,
    minSpacing: 1,
    maxSpacing: 5,
    defaultCrossBonded: true,
    vertical: GoldenVerticalExpectation(
      solution: 'Even Courses',
      totalCourses: 19,
      eaveBatten: 320,
      underEaveBatten: 220,
      ridgeOffset: 33,
      gauge: '18 @ 244',
    ),
    horizontal: GoldenHorizontalExpectation(
      solution: 'Even Sets',
      marks: '9 sets of 2 @ 610',
      firstMark: 605,
      secondMark: 758,
      actualSpacing: 5,
      designWidth: 6100,
      adjustedWidth: 6100,
      lhOverhang: 50,
      rhOverhang: 50,
    ),
  ),
  GoldenJobFixture(
    id: 'pantile',
    materialType: 'Pantile',
    slateTileHeight: 420,
    tileCoverWidth: 300,
    minGauge: 310,
    maxGauge: 345,
    minSpacing: 1,
    maxSpacing: 5,
    defaultCrossBonded: false,
    vertical: GoldenVerticalExpectation(
      solution: 'Even Courses',
      totalCourses: 15,
      eaveBatten: 345,
      underEaveBatten: null,
      ridgeOffset: 35,
      gauge: '14 @ 330',
    ),
    horizontal: GoldenHorizontalExpectation(
      solution: 'Even Sets',
      marks: '9 sets of 2 @ 610',
      firstMark: 605,
      secondMark: null,
      actualSpacing: 5,
      designWidth: 6100,
      adjustedWidth: 6100,
      lhOverhang: 50,
      rhOverhang: 50,
    ),
  ),
  GoldenJobFixture(
    id: 'interlocking-cross-bonded',
    materialType: 'Interlocking Tile',
    slateTileHeight: 420,
    tileCoverWidth: 300,
    minGauge: 310,
    maxGauge: 345,
    minSpacing: 1,
    maxSpacing: 5,
    defaultCrossBonded: true,
    vertical: GoldenVerticalExpectation(
      solution: 'Even Courses',
      totalCourses: 15,
      eaveBatten: 345,
      underEaveBatten: null,
      ridgeOffset: 35,
      gauge: '14 @ 330',
    ),
    horizontal: GoldenHorizontalExpectation(
      solution: 'Even Sets',
      marks: '9 sets of 2 @ 610',
      firstMark: 605,
      secondMark: 758,
      actualSpacing: 5,
      designWidth: 6100,
      adjustedWidth: 6100,
      lhOverhang: 50,
      rhOverhang: 50,
    ),
  ),
];

/// Mixed rafter heights within wet-ridge spread (max 25 mm between slopes).
const GoldenMultiRafterFixture kGoldenMultiRafterPlainTile = GoldenMultiRafterFixture(
  materialType: 'Plain Tile',
  rafterHeights: [5000, 5010, 4990],
  slateTileHeight: 265,
  minGauge: 85,
  maxGauge: 115,
  solution: 'Even Courses',
  ridgeOffsets: [40, 50, 30],
);

class GoldenMultiRafterFixture {
  final String materialType;
  final List<int> rafterHeights;
  final double slateTileHeight;
  final double minGauge;
  final double maxGauge;
  final String solution;
  final List<int> ridgeOffsets;

  const GoldenMultiRafterFixture({
    required this.materialType,
    required this.rafterHeights,
    required this.slateTileHeight,
    required this.minGauge,
    required this.maxGauge,
    required this.solution,
    required this.ridgeOffsets,
  });
}

TileModel tileModelFromGoldenFixture(GoldenJobFixture fixture) {
  return TileModel(
    id: 'golden-${fixture.id}',
    name: fixture.id,
    manufacturer: 'Golden',
    materialType: parseTileSlateTypeFromString(fixture.materialType),
    description: 'Golden job fixture',
    isPublic: true,
    isApproved: true,
    createdById: 'golden',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    slateTileHeight: fixture.slateTileHeight,
    tileCoverWidth: fixture.tileCoverWidth,
    minGauge: fixture.minGauge,
    maxGauge: fixture.maxGauge,
    minSpacing: fixture.minSpacing,
    maxSpacing: fixture.maxSpacing,
    defaultCrossBonded: fixture.defaultCrossBonded,
  );
}

