import 'dart:math';

import 'package:chessgame/pages/driveVideoPages/driveVideo.dart';
import 'package:flutter/material.dart';

final videoUrls = [
  'https://drive.google.com/uc?export=download&id=1xo8ngTSazUomg3yo7-I5bhY3K5VHY6MP',
  'https://drive.google.com/uc?export=download&id=1MAYVbstjYjW2zeUr9NsWmLsVVnWXHFXB',
  'https://drive.google.com/uc?export=download&id=1gSo6hIwMXiBZZEm2e2HS8UYF-MRNfzPh',
  'https://drive.google.com/uc?export=download&id=1d4EGye9qtt9z93DDJzK4-S6ycvrpFb2f',
  'https://drive.google.com/uc?export=download&id=1pjIqF0wx9a83J2EQAOwXSwPCBrp_DPmN',
  'https://drive.google.com/uc?export=download&id=1Ew1c_sc6wfuD2Wvw1Kgu6yjQrqp0_BYZ',
  'https://drive.google.com/uc?export=download&id=1yx4-IzbJcDjo9LvFDD3cjInLYKxSQUHl',
  'https://drive.google.com/uc?export=download&id=1NHp2Q03mQcfsXSEhv_4Xq16OvhwAqeGO',
];

class DriveFeed extends StatelessWidget {
  const DriveFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Drive Video Feed")),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple, Colors.indigo],
          ),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Drive Video Collection',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemCount: videoUrls.length,
                itemBuilder: (context, index) {
                  return _VideoThumbnail(
                    videoUrl: videoUrls[index],
                    index: index,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoThumbnail extends StatelessWidget {
  final String videoUrl;
  final int index;

  const _VideoThumbnail({
    super.key,
    required this.videoUrl,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final color = Colors.accents[index % Colors.accents.length];
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => Drivevideo(videoUrl: videoUrl),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),

        child: ClipRect(
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [color.withOpacity(0.6), color.withOpacity(0.3)],
                  ),
                ),
              ),
              const Center(
                child: Icon(Icons.play_circle, size: 50, color: Colors.white),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Video ${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Duration: ${(index + 5) * 30}s',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
