class ApiUser {
  final int id;
  final String name;
  final String mobileNumber;
  final String role;
  final bool registered;
  final String? image;
  final int? locationId;
  final String? occupation;

  const ApiUser({
    required this.id,
    required this.name,
    required this.mobileNumber,
    required this.role,
    required this.registered,
    this.image,
    this.locationId,
    this.occupation,
  });

  ApiUser copyWith({
    int? id,
    String? name,
    String? mobileNumber,
    String? role,
    bool? registered,
    String? image,
    int? locationId,
    String? occupation,
  }) {
    return ApiUser(
      id: id ?? this.id,
      name: name ?? this.name,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      role: role ?? this.role,
      registered: registered ?? this.registered,
      image: image ?? this.image,
      locationId: locationId ?? this.locationId,
      occupation: occupation ?? this.occupation,
    );
  }

  factory ApiUser.fromJson(Map<String, dynamic> json) {
    return ApiUser(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 1,
      name: json['name'] as String? ?? 'Guest User',
      mobileNumber: json['mobileNumber'] as String? ?? '',
      role: json['role'] as String? ?? 'GUEST',
      registered: json['registered'] as bool? ?? false,
      image: json['image'] as String?,
      locationId: json['locationId'] as int?,
      occupation: json['occupation'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'mobileNumber': mobileNumber,
    'role': role,
    'registered': registered,
    if (image != null) 'image': image,
    if (locationId != null) 'locationId': locationId,
    if (occupation != null) 'occupation': occupation,
  };
}

class AuthSession {
  final String token;
  final String tokenType;
  final int expiresIn;
  final ApiUser user;
  final bool isExistingUser;
  final List<String> accessibleWeddings;
  final String message;

  const AuthSession({
    required this.token,
    this.tokenType = 'Bearer',
    required this.expiresIn,
    required this.user,
    this.isExistingUser = false,
    required this.accessibleWeddings,
    required this.message,
  });

  AuthSession copyWith({
    String? token,
    String? tokenType,
    int? expiresIn,
    ApiUser? user,
    bool? isExistingUser,
    List<String>? accessibleWeddings,
    String? message,
  }) {
    return AuthSession(
      token: token ?? this.token,
      tokenType: tokenType ?? this.tokenType,
      expiresIn: expiresIn ?? this.expiresIn,
      user: user ?? this.user,
      isExistingUser: isExistingUser ?? this.isExistingUser,
      accessibleWeddings: accessibleWeddings ?? this.accessibleWeddings,
      message: message ?? this.message,
    );
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>? ?? {};
    final weddings = (json['accessibleWeddings'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        ['sanvi-santosh'];

    final isExisting = json['isExistingUser'] as bool? ??
        (userJson['registered'] as bool? ?? false);

    return AuthSession(
      token: json['token'] as String? ?? 'guest-demo-token',
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      expiresIn: json['expiresIn'] is int ? json['expiresIn'] : 604800,
      user: ApiUser.fromJson(userJson),
      isExistingUser: isExisting,
      accessibleWeddings: weddings,
      message: json['message'] as String? ?? 'Authentication successful',
    );
  }

  Map<String, dynamic> toJson() => {
    'token': token,
    'tokenType': tokenType,
    'expiresIn': expiresIn,
    'user': user.toJson(),
    'isExistingUser': isExistingUser,
    'accessibleWeddings': accessibleWeddings,
    'message': message,
  };
}

