import 'package:image_picker/image_picker.dart';

/// 포트홀 사진 선택 상태를 관리하는 클래스
class PhotoSelectionState {
  PhotoSelectionState({
    List<XFile>? selectedImages,
    this.maxImages = 6,
  }) : selectedImages = selectedImages ?? [];

  final List<XFile> selectedImages;
  final int maxImages;

  /// 선택된 이미지가 있는지 확인
  bool get hasImages => selectedImages.isNotEmpty;

  /// 더 많은 이미지를 추가할 수 있는지 확인
  bool get canAddMore => selectedImages.length < maxImages;

  /// 이미지 개수 텍스트 반환
  String get imageCountText => "${selectedImages.length}/$maxImages";

  /// 가장 최근 선택된 이미지 반환 (대표 이미지용)
  XFile? get latestImage => selectedImages.isNotEmpty ? selectedImages.last : null;

  /// 새로운 이미지를 추가한 상태 반환
  PhotoSelectionState addImage(XFile image) {
    if (!canAddMore) return this;

    final newImages = List<XFile>.from(selectedImages)..add(image);
    return PhotoSelectionState(
      selectedImages: newImages,
      maxImages: maxImages,
    );
  }

  /// 여러 이미지를 추가한 상태 반환
  PhotoSelectionState addImages(List<XFile> images) {
    final availableSlots = maxImages - selectedImages.length;
    final imagesToAdd = images.take(availableSlots).toList();

    final newImages = List<XFile>.from(selectedImages)..addAll(imagesToAdd);
    return PhotoSelectionState(
      selectedImages: newImages,
      maxImages: maxImages,
    );
  }

  /// 특정 인덱스의 이미지를 제거한 상태 반환
  PhotoSelectionState removeImage(int index) {
    if (index < 0 || index >= selectedImages.length) return this;

    final newImages = List<XFile>.from(selectedImages)..removeAt(index);
    return PhotoSelectionState(
      selectedImages: newImages,
      maxImages: maxImages,
    );
  }

  /// 모든 이미지를 제거한 상태 반환
  PhotoSelectionState clearImages() {
    return PhotoSelectionState(maxImages: maxImages);
  }

  /// 특정 슬롯에 이미지가 있는지 확인
  bool hasImageAt(int index) {
    return index < selectedImages.length;
  }

  /// 특정 슬롯의 이미지 반환
  XFile? getImageAt(int index) {
    return hasImageAt(index) ? selectedImages[index] : null;
  }

  @override
  String toString() {
    return 'PhotoSelectionState(selectedImages: ${selectedImages.length}, maxImages: $maxImages)';
  }
}