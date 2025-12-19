import 'dart:io';
import 'package:external_app_launcher/external_app_launcher.dart';

class AppLinks {
  static Future<bool> _openPackage(String package) async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await LaunchApp.openApp(
        androidPackageName: package,
        openStore: true,
        appStoreLink: 'market://details?id=$package',
      );
      return result == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> openNetflix() => _openPackage('com.netflix.mediaclient');
  static Future<bool> openCrunchyroll() =>
      _openPackage('com.crunchyroll.crunchyroid');
  static Future<bool> openSoundCloud() =>
      _openPackage('com.soundcloud.android');
  static Future<bool> openSteam() =>
      _openPackage('com.valvesoftware.android.steam.community');
  static Future<bool> openMetaTrader4() =>
      _openPackage('net.metaquotes.metatrader4');
  static Future<bool> openTradeRepublic() =>
      _openPackage('de.traderepublic.app');
  static Future<bool> openImagin() => _openPackage('com.imaginbank.app');
  static Future<bool> openChess() => _openPackage('com.chess');
  static Future<bool> openCinesa() =>
      _openPackage('nz.co.vista.android.movie.cinesa');
  static Future<bool> openTranslate() =>
      _openPackage('com.google.android.apps.translate');
  static Future<bool> openAliExpress() =>
      _openPackage('com.alibaba.aliexpresshd');
  static Future<bool> openGuitarTuna() => _openPackage('com.ovelin.guitartuna');
  static Future<bool> openGlovo() => _openPackage('com.glovo');
  static Future<bool> openAmazon() =>
      _openPackage('com.amazon.mShop.android.shopping');
  static Future<bool> openFrogWeather() =>
      _openPackage('jp.miyavi.androiod.gnws');
  static Future<bool> openShein() => _openPackage('com.zzkko');
  static Future<bool> openCanvas() => _openPackage('com.instructure.candroid');
  static Future<bool> openPlayStationApp() =>
      _openPackage('com.scee.psxandroid');
  static Future<bool> openInvesting() =>
      _openPackage('com.fusionmedia.investing');
  static Future<bool> openMiDGT() => _openPackage('com.dgt.midgt');
  static Future<bool> openChatGPT() => _openPackage('com.openai.chatgpt');
  static Future<bool> openZalando() => _openPackage('de.zalando.mobile');
  static Future<bool> openExness() => _openPackage('com.exness.android.pa');
  static Future<bool> openDiscord() => _openPackage('com.discord');
  static Future<bool> openYoutube() => _openPackage('com.google.android.youtube');
  static Future<bool> openWikipedia() => _openPackage('org.wikipedia');
  static Future<bool> openGithub() => _openPackage('com.github.android');
  static Future<bool> openWolframAlpha() => _openPackage('com.wolfram.android.alpha');
  static Future<bool> openGoogleScholar() => _openPackage('com.google.android.apps.scholar');

  static Future<bool> openMapQuery(String query) =>
      _openPackage('com.google.android.apps.maps');
}
