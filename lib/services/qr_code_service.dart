// lib/services/qr_code_service.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:share_plus/share_plus.dart';

class QRCodeService {
  // 招待用QRコードを生成
  static Widget generateInvitationQR({
    required String invitationCode,
    required String petName,
    double size = 200.0,
  }) {
    final qrData =
        'reptitrack://invite?code=$invitationCode&pet=${Uri.encodeComponent(petName)}';

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: size,
            backgroundColor: Colors.white,
            eyeStyle: QrEyeStyle(color: Colors.black),
            dataModuleStyle: QrDataModuleStyle(color: Colors.black),
            errorCorrectionLevel: QrErrorCorrectLevel.M,
          ),
          SizedBox(height: 12),
          Text(
            '招待コード: $invitationCode',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 4),
          Text(
            petName,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // QRコード招待を共有
  static Future<void> shareInvitationQR({
    required String invitationCode,
    required String petName,
    required DateTime expiresAt,
  }) async {
    final shareText = '''
🦎 ReptiTrackへの招待

$petNameの飼育記録を共有します。

招待コード: $invitationCode

以下の方法で参加できます：
1. ReptiTrackアプリをダウンロード
2. 「招待コードで参加」から上記コードを入力
3. またはQRコードをスキャン

※有効期限: ${_formatDate(expiresAt)}まで
''';

    await Share.share(shareText, subject: 'ReptiTrack - ペット共有への招待');
  }

  static String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }
}

// QRコードスキャナー画面
class QRScannerScreen extends StatefulWidget {
  final Function(String code) onCodeScanned;

  const QRScannerScreen({super.key, required this.onCodeScanned});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isScanning = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QRコードをスキャン'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.flash_on),
            onPressed: () async {
              await controller?.toggleFlash();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                QRView(
                  key: qrKey,
                  onQRViewCreated: _onQRViewCreated,
                  overlay: QrScannerOverlayShape(
                    borderColor: Theme.of(context).primaryColor,
                    borderRadius: 10,
                    borderLength: 30,
                    borderWidth: 10,
                    cutOutSize: 250,
                  ),
                ),
                // スキャンエリアの説明
                Positioned(
                  bottom: 80,
                  left: 0,
                  right: 0,
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'ReptiTrackの招待QRコードをスキャンしてください',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.black,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'QRコードを枠内に合わせてください',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('手動で招待コードを入力'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;

    controller.scannedDataStream.listen((scanData) {
      if (isScanning && scanData.code != null) {
        setState(() {
          isScanning = false;
        });

        // ReptiTrackの招待リンクかチェック
        final code = _extractInvitationCode(scanData.code!);
        if (code != null) {
          widget.onCodeScanned(code);
          if (mounted) {
            Navigator.of(context).pop();
          }
        } else {
          // 無効なQRコードの場合
          _showInvalidQRDialog();
          Future.delayed(Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                isScanning = true;
              });
            }
          });
        }
      }
    });
  }

  // 招待コードを抽出
  String? _extractInvitationCode(String qrData) {
    // ReptiTrackの招待リンクの形式をチェック
    final uri = Uri.tryParse(qrData);
    if (uri?.scheme == 'reptitrack' && uri?.host == 'invite') {
      return uri?.queryParameters['code'];
    }

    // 直接招待コードが入力されている場合（8文字の英数字）
    if (RegExp(r'^[A-Z0-9]{8}$').hasMatch(qrData)) {
      return qrData;
    }

    return null;
  }

  void _showInvalidQRDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('無効なQRコード'),
            content: Text('ReptiTrackの招待QRコードではありません。\n正しいQRコードをスキャンしてください。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}

// QRコード表示ダイアログ
class QRCodeDialog extends StatelessWidget {
  final String invitationCode;
  final String petName;
  final DateTime expiresAt;

  const QRCodeDialog({
    super.key,
    required this.invitationCode,
    required this.petName,
    required this.expiresAt,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ペット共有の招待', style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 16),
            QRCodeService.generateInvitationQR(
              invitationCode: invitationCode,
              petName: petName,
              size: 200,
            ),
            SizedBox(height: 16),
            Text(
              '有効期限: ${_formatDate(expiresAt)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('閉じる'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    await QRCodeService.shareInvitationQR(
                      invitationCode: invitationCode,
                      petName: petName,
                      expiresAt: expiresAt,
                    );
                  },
                  icon: Icon(Icons.share),
                  label: Text('共有'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }
}
