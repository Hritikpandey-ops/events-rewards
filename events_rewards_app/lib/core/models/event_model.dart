
class EventModel {
  final String id;
  final String title;
  final String description;
  final String? category;        
  final String location;
  final DateTime startDate;
  final DateTime? endDate;       
  final String? bannerImage;     
  final int currentParticipants;
  final int? maxParticipants;    
  final bool isActive;
  final bool isRegistered;
  final DateTime createdAt;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    this.category,               
    required this.location,
    required this.startDate,
    this.endDate,                
    this.bannerImage,            
    this.currentParticipants = 0,
    this.maxParticipants,        
    this.isActive = true,
    this.isRegistered = false,
    required this.createdAt,
  });

  // Factory constructor from JSON
  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String?,  
      location: json['location'] as String? ?? '',
      
      startDate: json['eventdate'] != null 
          ? DateTime.parse(json['eventdate'] as String)
          : (json['startdate'] != null 
              ? DateTime.parse(json['startdate'] as String)
              : DateTime.now()),
      
      endDate: json['enddate'] != null 
          ? DateTime.parse(json['enddate'] as String) 
          : null,
      
      bannerImage: json['bannerimage'] as String?, 
      currentParticipants: json['currentparticipants'] as int? ?? 0,
      maxParticipants: json['maxparticipants'] as int?, 
      isActive: json['isactive'] as bool? ?? true,
      isRegistered: json['isregistered'] as bool? ?? false,
      
      createdAt: json['createdat'] != null 
          ? DateTime.parse(json['createdat'] as String)
          : DateTime.now(),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'banner_image': bannerImage,
      'current_participants': currentParticipants,
      'max_participants': maxParticipants,
      'is_active': isActive,
      'is_registered': isRegistered,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper getters
  bool get isPast => DateTime.now().isAfter(endDate ?? startDate);
  bool get isUpcoming => DateTime.now().isBefore(startDate);
  bool get isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(startDate.year, startDate.month, startDate.day);
    return today == eventDay;
  }

  bool get hasAvailableSlots {
    if (maxParticipants == null) return true;
    return currentParticipants < maxParticipants!;
  }

  String get formattedDate {
    final day = startDate.day.toString().padLeft(2, '0');
    final month = startDate.month.toString().padLeft(2, '0');
    final year = startDate.year;
    return '$day/$month/$year';
  }

  String get formattedTime {
    final hour = startDate.hour.toString().padLeft(2, '0');
    final minute = startDate.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Copy with method
  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    String? bannerImage,
    int? currentParticipants,
    int? maxParticipants,
    bool? isActive,
    bool? isRegistered,
    DateTime? createdAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      bannerImage: bannerImage ?? this.bannerImage,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      isActive: isActive ?? this.isActive,
      isRegistered: isRegistered ?? this.isRegistered,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'EventModel(id: $id, title: $title, date: $formattedDate, isRegistered: $isRegistered)';
  }
}