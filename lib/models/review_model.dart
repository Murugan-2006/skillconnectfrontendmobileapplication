class ReviewModel {
  final String id;
  final String bookingId;
  final int rating;
  final String comment;

  ReviewModel({
    required this.id,
    required this.bookingId,
    required this.rating,
    required this.comment,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['_id'] ?? json['id'] ?? '',
      bookingId: json['bookingId'] ?? '',
      rating: json['rating'] ?? 5,
      comment: json['comment'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'rating': rating,
      'comment': comment,
    };
  }
}
