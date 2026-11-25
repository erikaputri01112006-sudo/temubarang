class ItemModel {
  const ItemModel({
    required this.id,
    required this.userId,
    this.categoryId,
    this.areaId,
    required this.type,
    required this.title,
    required this.description,
    required this.locationDetail,
    required this.incidentDate,
    this.imageUrl,
    required this.whatsappContact,
    required this.status,
    required this.createdAt,
    this.reporterName,
    this.categoryName,
    this.areaName,
  });

  final String id;
  final String userId;
  final int? categoryId;
  final int? areaId;
  final String type; // 'lost' | 'found'
  final String title;
  final String description;
  final String locationDetail;
  final DateTime incidentDate;
  final String? imageUrl;
  final String whatsappContact;
  final String status; // 'open' | 'resolved'
  final DateTime createdAt;
  final String? reporterName;
  final String? categoryName;
  final String? areaName;

  bool get isLost => type == 'lost';
  bool get isFound => type == 'found';
  bool get isResolved => status == 'resolved';
  String get typeLabel => isLost ? 'Barang Hilang' : 'Barang Temuan';

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    final category = json['categories'] as Map<String, dynamic>?;
    final area = json['areas'] as Map<String, dynamic>?;

    return ItemModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: (json['category_id'] as num?)?.toInt(),
      areaId: (json['area_id'] as num?)?.toInt(),
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      locationDetail: json['location_detail'] as String,
      incidentDate: DateTime.parse(json['incident_date'] as String),
      imageUrl: json['image_url'] as String?,
      whatsappContact: json['whatsapp_contact'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      reporterName: profile?['full_name'] as String?,
      categoryName: category?['name'] as String?,
      areaName: area?['name'] as String?,
    );
  }
}
