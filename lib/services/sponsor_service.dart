//lib\services\sponsor_service.dart
import '../core/config/supabase_config.dart';
import '../models/sponsor_banner_model.dart';
class SponsorService { final _db=SupabaseConfig.client; Future<List<SponsorBannerModel>> activeBanners() async { final d=await _db.from('sponsor_banners').select().eq('is_active', true).order('display_order'); return (d as List).map((e)=>SponsorBannerModel.fromMap(Map<String,dynamic>.from(e))).toList(); }}
