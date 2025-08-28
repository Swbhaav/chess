import 'dart:io';
import 'package:chessgame/services/auth/googleAuthClient.dart';
import 'package:googleapis/drive/v3.dart' as ga;
import 'package:googleapis_auth/auth_io.dart';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

const _clientId =
    "229562450429-62ckgsvp3pi1l11pkprs70lmodek5vm3.apps.googleusercontent.com";
const _scopes = ['https://www.googleapis.com/auth/drive.file'];

class GoogleDrive {
  final storage = SecureStorage();

  static const List<String> _allowedVideoExtensions = [
    '.mp4',
    '.mov',
    '.avi',
    '.mkv',
    '.wmv',
    '.flv',
    '.webm',
    '.mpeg',
    '.mpg',
  ];

  //Get Authenticated Http Client
  Future<http.Client> getHttpClient() async {
    try {
      // Get existing credentials
      var credentials = await storage.getCredentials();

      if (credentials != null) {
        // Check if token is expired
        final expiry = DateTime.tryParse(credentials["expiry"] ?? '');
        if (expiry != null && expiry.isAfter(DateTime.now())) {
          // Token is still valid
          return authenticatedClient(
            http.Client(),
            AccessCredentials(
              AccessToken(
                credentials["type"] ?? 'Bearer',
                credentials["data"],
                expiry,
              ),
              credentials["refreshToken"],
              _scopes,
            ),
          );
        }
      }

      // Need new authentication
      var authClient = await clientViaUserConsent(
        ClientId(_clientId),
        _scopes,
        (url) async {
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url));
          } else {
            throw Exception('Could not launch $url');
          }
        },
      );

      // Save new credentials
      await storage.saveCredentials(
        authClient.credentials.accessToken,
        authClient.credentials.refreshToken ?? '',
        authClient.credentials.expiry.toIso8601String(),
      );

      return authClient;
    } catch (e) {
      print('Authentication error: $e');
      rethrow;
    }
  }

  // check if the directory forlder is already available in drive , if available return its id
  // if not available create a folder in drive and return id
  //   if not able to create id then it means user authetication has failed
  Future<String?> _getFolderId(ga.DriveApi driveApi) async {
    final mimeType = "application/vnd.google-apps.folder";
    String folderName = "personalDiaryBackup";

    try {
      final found = await driveApi.files.list(
        q: "mimeType = '$mimeType' and name = '$folderName'",
        $fields: "files(id, name)",
      );
      final files = found.files;
      if (files == null) {
        print("Sign-in first Error");
        return null;
      }

      // The folder already exists
      if (files.isNotEmpty) {
        return files.first.id;
      }

      // Create a folder
      ga.File folder = ga.File();
      folder.name = folderName;
      folder.mimeType = mimeType;
      final folderCreation = await driveApi.files.create(folder);
      print("Folder ID: ${folderCreation.id}");

      return folderCreation.id;
    } catch (e) {
      print(e);
      return null;
    }
  }

  uploadFileToGoogleDrive(File file) async {
    final String fileExtension = p.extension(file.path).toLowerCase();
    if (!_allowedVideoExtensions.contains(fileExtension)) {
      print("Error: only video files ($_allowedVideoExtensions) are allowed");
      return;
    }
    var client = await getHttpClient();
    var drive = ga.DriveApi(client);
    String? folderId = await _getFolderId(drive);
    if (folderId == null) {
      print("Sign-in first Error");
    } else {
      ga.File fileToUpload = ga.File();
      fileToUpload.parents = [folderId];
      fileToUpload.name = p.basename(file.absolute.path);
      var response = await drive.files.create(
        fileToUpload,
        uploadMedia: ga.Media(file.openRead(), file.lengthSync()),
      );
      print(response);
    }
  }

  Future<String?> getVideoUrl(String fileName) async {
    var client = await getHttpClient();
    var drive = ga.DriveApi(client);
    String? folderId = await _getFolderId(drive);
    if (folderId == null) {
      print("Sign-in first Error");
      return null;
    }
    try {
      final found = await drive.files.list(
        q: "'$folderId' in parents and name = '$fileName'",
        $fields: "files(id, name, webContentLink, webViewLink)",
      );
      final files = found.files;
      if (files == null || files.isEmpty) {
        print("Files not found: $fileName");
        return null;
      }

      await _setFilePermission(drive, files.first.id!);

      return files.first.webContentLink;
    } catch (e) {
      print("Error retrieving video: $e");
      return null;
    }
  }

  Future<void> _setFilePermission(ga.DriveApi driveApi, String fileId) async {
    try {
      var permission = ga.Permission()
        ..type = 'anyone'
        ..role = 'reader';
      await driveApi.permissions.create(permission, fileId);
      print("Permission set for file ID: $fileId");
    } catch (e) {
      print("Error setting permission");
    }
  }
}

extension on AccessCredentials {
  get expiry => null;
}
