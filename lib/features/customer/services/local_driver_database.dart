class LocalDriverDatabase {
  // 10 Locations
  // 1. Chợ Bến Thành (Quận 1): 10.7725, 106.6980
  // 2. Landmark 81 (Bình Thạnh): 10.7950, 106.7218
  // 3. Sân bay Tân Sơn Nhất (Tân Bình): 10.8143, 106.6669
  // 4. Cầu Ánh Sao (Quận 7): 10.7257, 106.7169
  // 5. Công viên Đầm Sen (Quận 11): 10.7670, 106.6378
  // 6. Khu du lịch Suối Tiên (Thủ Đức): 10.8631, 106.8028
  // 7. Chùa Hoằng Pháp (Hóc Môn): 10.8841, 106.5891
  // 8. AEON Mall Bình Tân (Bình Tân): 10.7410, 106.6083
  // 9. Làng Đại học Quốc gia (Thủ Đức/Dĩ An): 10.8700, 106.8024
  // 10. Phà Bình Khánh (Nhà Bè/Cần Giờ): 10.6698, 106.7562

  static final List<Map<String, dynamic>> drivers = [
    // 1. Chợ Bến Thành
    {
      'id': 'drv_1_bike',
      'name': 'Gia Kỳ (Chợ Bến Thành)',
      'providerName': 'GrabBike',
      'type': 'bike',
      'rating': 4.9,
      'ratingCount': 120,
      'latitude': 10.7725,
      'longitude': 106.6980,
    },
    {
      'id': 'drv_1_car',
      'name': 'Thanh Sang (Chợ Bến Thành)',
      'providerName': 'GrabCar',
      'type': 'car',
      'rating': 4.8,
      'ratingCount': 85,
      'latitude': 10.7726,
      'longitude': 106.6981,
    },

    // 2. Landmark 81
    {
      'id': 'drv_2_bike',
      'name': 'Văn Toàn (Landmark 81)',
      'providerName': 'BeBike',
      'type': 'bike',
      'rating': 4.7,
      'ratingCount': 34,
      'latitude': 10.7950,
      'longitude': 106.7218,
    },
    {
      'id': 'drv_2_car',
      'name': 'Quốc Bảo (Landmark 81)',
      'providerName': 'Xanh SM Car',
      'type': 'car',
      'rating': 5.0,
      'ratingCount': 210,
      'latitude': 10.7951,
      'longitude': 106.7219,
    },

    // 3. Sân bay Tân Sơn Nhất
    {
      'id': 'drv_3_bike',
      'name': 'Minh Quân (Sân bay TSN)',
      'providerName': 'Xanh SM Bike',
      'type': 'bike',
      'rating': 4.6,
      'ratingCount': 92,
      'latitude': 10.8143,
      'longitude': 106.6669,
    },
    {
      'id': 'drv_3_car',
      'name': 'Đăng Khoa (Sân bay TSN)',
      'providerName': 'BeCar',
      'type': 'car',
      'rating': 4.8,
      'ratingCount': 145,
      'latitude': 10.8144,
      'longitude': 106.6670,
    },

    // 4. Cầu Ánh Sao, Phú Mỹ Hưng
    {
      'id': 'drv_4_bike',
      'name': 'Tuấn Vũ (Cầu Ánh Sao)',
      'providerName': 'GrabBike',
      'type': 'bike',
      'rating': 4.9,
      'ratingCount': 324,
      'latitude': 10.7257,
      'longitude': 106.7169,
    },
    {
      'id': 'drv_4_car',
      'name': 'Hoàng Nam (Cầu Ánh Sao)',
      'providerName': 'GrabCar',
      'type': 'car',
      'rating': 4.7,
      'ratingCount': 42,
      'latitude': 10.7258,
      'longitude': 106.7170,
    },

    // 5. Công viên Đầm Sen
    {
      'id': 'drv_5_bike',
      'name': 'Hữu Tín (CV Đầm Sen)',
      'providerName': 'BeBike',
      'type': 'bike',
      'rating': 4.5,
      'ratingCount': 19,
      'latitude': 10.7670,
      'longitude': 106.6378,
    },
    {
      'id': 'drv_5_car',
      'name': 'Tiến Đạt (CV Đầm Sen)',
      'providerName': 'BeCar',
      'type': 'car',
      'rating': 4.8,
      'ratingCount': 67,
      'latitude': 10.7671,
      'longitude': 106.6379,
    },

    // 6. Khu du lịch Suối Tiên
    {
      'id': 'drv_6_bike',
      'name': 'Phúc Hưng (Suối Tiên)',
      'providerName': 'Xanh SM Bike',
      'type': 'bike',
      'rating': 4.9,
      'ratingCount': 110,
      'latitude': 10.8631,
      'longitude': 106.8028,
    },
    {
      'id': 'drv_6_car',
      'name': 'Công Trí (Suối Tiên)',
      'providerName': 'Xanh SM Car',
      'type': 'car',
      'rating': 5.0,
      'ratingCount': 350,
      'latitude': 10.8632,
      'longitude': 106.8029,
    },

    // 7. Chùa Hoằng Pháp
    {
      'id': 'drv_7_bike',
      'name': 'Thiện Tâm (Chùa Hoằng Pháp)',
      'providerName': 'GrabBike',
      'type': 'bike',
      'rating': 4.9,
      'ratingCount': 90,
      'latitude': 10.8841,
      'longitude': 106.5891,
    },
    {
      'id': 'drv_7_car',
      'name': 'Bảo Long (Chùa Hoằng Pháp)',
      'providerName': 'GrabCar',
      'type': 'car',
      'rating': 4.9,
      'ratingCount': 88,
      'latitude': 10.8842,
      'longitude': 106.5892,
    },

    // 8. AEON Mall Bình Tân
    {
      'id': 'drv_8_bike',
      'name': 'Mạnh Dũng (AEON Bình Tân)',
      'providerName': 'BeBike',
      'type': 'bike',
      'rating': 4.8,
      'ratingCount': 32,
      'latitude': 10.7410,
      'longitude': 106.6083,
    },
    {
      'id': 'drv_8_car',
      'name': 'Trí Cường (AEON Bình Tân)',
      'providerName': 'BeCar',
      'type': 'car',
      'rating': 4.6,
      'ratingCount': 14,
      'latitude': 10.7411,
      'longitude': 106.6084,
    },

    // 9. Làng Đại học Quốc gia
    {
      'id': 'drv_9_bike',
      'name': 'Thanh Sơn (Làng ĐHQG)',
      'providerName': 'Xanh SM Bike',
      'type': 'bike',
      'rating': 4.9,
      'ratingCount': 250,
      'latitude': 10.8700,
      'longitude': 106.8024,
    },
    {
      'id': 'drv_9_car',
      'name': 'Vĩnh Lộc (Làng ĐHQG)',
      'providerName': 'Xanh SM Car',
      'type': 'car',
      'rating': 4.8,
      'ratingCount': 120,
      'latitude': 10.8701,
      'longitude': 106.8025,
    },

    // 10. Phà Bình Khánh
    {
      'id': 'drv_10_bike',
      'name': 'Nhựt Hảo (Phà Bình Khánh)',
      'providerName': 'GrabBike',
      'type': 'bike',
      'rating': 4.7,
      'ratingCount': 50,
      'latitude': 10.6698,
      'longitude': 106.7562,
    },
    {
      'id': 'drv_10_car',
      'name': 'Quang Huy (Phà Bình Khánh)',
      'providerName': 'GrabCar',
      'type': 'car',
      'rating': 4.9,
      'ratingCount': 210,
      'latitude': 10.6699,
      'longitude': 106.7563,
    },
  ];
}
