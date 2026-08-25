import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/ai_service.dart';

final aiServiceProvider = Provider<AiService>((ref) => AiService());
