import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trip_model.dart';

class TripListNotifier extends Notifier<List<Trip>> {
  @override
  List<Trip> build() {
    // Dummy state matching DB schema perfectly
    return [
      Trip(
        id: '1',
        destination: 'Manali, Himachal',
        startDate: DateTime(2024, 5, 10),
        endDate: DateTime(2024, 5, 14),
        budget: 12000,
        spent: 9450,
        imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCixxv-3Qlw7ZrAzwZ5mbyeow_i0pWCc6DYu2JPrWSDTb1odlO3glgZpzdbLNiYlha5wMCvjKKBv3urFl33Y-QZOcWGPVW9i_02CzQWz7mk6vlxMGpx9B3yFshKg9-MjQtLlG5Gt4QJrTlnZYsRoYlBZfsC6I7QR0myWV2NSrwfQ0IUvaaKCbCJqvSOLooAnZoY7ai8gxsh3LJjA0PFlGHrguP4Qv62lsXElZ1hdrvlO23MyZvtisSq',
        weatherTemp: 18,
      ),
      Trip(
        id: '2',
        destination: 'Goa',
        startDate: DateTime(2024, 4, 20),
        endDate: DateTime(2024, 4, 24),
        budget: 15000,
        spent: 11250,
        imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuB2vb0y_efOe1blA6pqPx6rlDAdMDJzY3hB-WaxDMvKydL9oGdThb-fECUzDuZVlHvX63sui7bLLR8QszOnETR8jkySvdSIwRfVEHtQzhPLKI131tz1S360hchzt86eUp5qY7JfVNd5KWSC_Dk1ZJLvyByD3fHay-HkONwpGDzPWjsTOsQiPzH7TiSKqBhmgi0BD-8ttHD2CgFFyITImitSerE641PqQugkByJ9JbGihvGLNWym_73X',
        weatherTemp: 29,
      ),
      Trip(
        id: '3',
        destination: 'Jaipur, Rajasthan',
        startDate: DateTime(2024, 3, 12),
        endDate: DateTime(2024, 3, 15),
        budget: 8000,
        spent: 6200,
        imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCd5Yc65FIicKVnpcmCIE7VuU9_uxSTzvEU_trDaj29inHqVjL-Qq7sLca4l356XouwQZ-jzxV4G3ryjli3FWtpKHYAu7fiiL_GpIuiBRDT5rq54HHvngREJEv0zmcEJWlMPAuQHepDwOVlmTaqDz4Q186Usf9fa7kit6vVrEFpVEDVAtSZGuiBQMeJKg_HjlXKtx1LS0tgOuZlY086rtwKb9ns0SsRRSGMsdrCu8Sh5I7bWnhJ-29k',
        weatherTemp: 32,
      ),
    ];
  }
}

final tripListProvider = NotifierProvider<TripListNotifier, List<Trip>>(TripListNotifier.new);
