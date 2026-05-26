import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:zirofit_fl/features/workout/services/voice_log_service.dart';

/// iOS-aligned inline voice log overlay matching WorkoutSessionView.swift
/// voiceLogOverlay: full-screen blur, audio-reactive mic pulse, fixed 250pt
/// transcription area, bottom command card with Confirm/Change, auto-confirm.
class VoiceLogOverlay extends StatefulWidget {
  const VoiceLogOverlay({
    super.key,
    required this.service,
    this.knownExercises = const [],
    this.libraryExercises = const [],
    required this.onChangeExercise,
    required this.onConfirm,
  });

  final VoiceLogService service;
  final List<String> knownExercises;
  final List<String> libraryExercises;
  final void Function(String exerciseName) onChangeExercise;
  final void Function(ParsedVoiceInput) onConfirm;

  @override
  State<VoiceLogOverlay> createState() => _VoiceLogOverlayState();
}

enum _VoicePhase { listening, processing, command, error }

class _VoiceLogOverlayState extends State<VoiceLogOverlay>
    with SingleTickerProviderStateMixin {
  _VoicePhase _phase = _VoicePhase.listening;
  ParsedVoiceInput? _latestCommand;
  String _transcription = '', _errorText = '';
  bool _isConfirming = false;
  Timer? _autoConfirmTimer;
  late AnimationController _audioCtrl;
  late Animation<double> _audioAnim;

  @override
  void initState() {
    super.initState();
    _audioCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _audioAnim = Tween(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _audioCtrl, curve: Curves.easeInOutSine),
    );
    _audioCtrl.repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startVoice());
  }

  @override
  void dispose() {
    _autoConfirmTimer?.cancel();
    _audioCtrl.dispose();
    widget.service.stopListening();
    super.dispose();
  }

  Future<void> _startVoice() async {
    try {
      final text = await widget.service.startListening();
      if (!mounted) return;
      _audioCtrl.stop();
      if (text == null || text.trim().isEmpty) {
        return setState(() { _phase = _VoicePhase.error; _errorText = 'No speech detected. Please try again.'; });
      }
      setState(() { _transcription = text; _phase = _VoicePhase.processing; });
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      final parsed = widget.service.parse(text, knownExercises: widget.knownExercises, libraryExercises: widget.libraryExercises);
      if (parsed == null) {
        setState(() { _phase = _VoicePhase.error; _errorText = 'Could not understand. Try: "Bench press 50 kg 5 reps"'; });
      } else {
        setState(() { _latestCommand = parsed; _phase = _VoicePhase.command; });
        _autoConfirmTimer = Timer(const Duration(milliseconds: 1500), () {
          if (mounted && !_isConfirming) { _isConfirming = true; widget.onConfirm(parsed); }
        });
      }
    } catch (e) {
      if (!mounted) return;
      _audioCtrl.stop();
      setState(() { _phase = _VoicePhase.error; _errorText = 'Speech recognition error: $e'; });
    }
  }

  void _onConfirm() {
    if (_isConfirming || _latestCommand == null) return;
    _autoConfirmTimer?.cancel();
    _isConfirming = true;
    widget.onConfirm(_latestCommand!);
  }

  void _onChange() {
    _autoConfirmTimer?.cancel();
    if (_latestCommand != null) widget.onChangeExercise(_latestCommand!.exerciseName ?? '');
  }

  void _retry() {
    setState(() { _phase = _VoicePhase.listening; _transcription = ''; _errorText = ''; _latestCommand = null; _isConfirming = false; });
    _audioCtrl.repeat(reverse: true);
    _startVoice();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(children: [
      Positioned.fill(child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(color: Colors.black.withValues(alpha: 0.45)),
      )),
      SafeArea(child: Column(children: [
        const Spacer(flex: 2),
        SizedBox(height: 160, child: AnimatedBuilder(animation: _audioAnim, builder: (_, _) {
          final lv = _audioAnim.value, rec = _phase == _VoicePhase.listening;
          final c = rec ? Colors.red : (_phase == _VoicePhase.command ? Colors.green : Colors.blue);
          return Center(child: Stack(alignment: Alignment.center, children: [
            Container(width: 100 + lv * 250, height: 100 + lv * 250, decoration: BoxDecoration(shape: BoxShape.circle, color: c.withValues(alpha: 0.1))),
            Container(width: 70 + lv * 120, height: 70 + lv * 120, decoration: BoxDecoration(shape: BoxShape.circle, color: c.withValues(alpha: 0.2))),
            Icon(rec ? Icons.mic : Icons.check_circle, size: 40, color: c),
          ]));
        })),
        const SizedBox(height: 20),
        SizedBox(height: 250, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 30), child: Column(children: [
          SizedBox(height: 180, child: Align(alignment: Alignment.topCenter, child: Text(
            _transcription.isNotEmpty ? _transcription : _phase == _VoicePhase.listening ? 'Listening...' : '',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center,
          ))),
          if (_phase == _VoicePhase.listening && _transcription.isEmpty)
            Text("Say something like 'Bench press 50 kg 5 reps'",
              style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7)), textAlign: TextAlign.center)
          else if (_phase == _VoicePhase.processing)
            const Text('Processing final words...', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueAccent))
          else if (_phase == _VoicePhase.error)
            Padding(padding: const EdgeInsets.only(top: 8), child: Text(_errorText,
              style: TextStyle(fontSize: 14, color: Colors.red.shade300), textAlign: TextAlign.center)),
        ]))),
        const Spacer(flex: 3),
      ])),
      if (_phase == _VoicePhase.command && _latestCommand != null)
        _buildCard(theme),
      if (_phase == _VoicePhase.error)
        Positioned(left: 0, right: 0, bottom: 120, child: Center(child: TextButton.icon(
          onPressed: _retry, icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
          label: const Text('Try Again', style: TextStyle(color: Colors.white, fontSize: 16)),
        ))),
    ]);
  }

  Widget _buildCard(ThemeData theme) {
    final cmd = _latestCommand!;
    return Positioned(left: 16, right: 16, bottom: 120, child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0), duration: const Duration(milliseconds: 300), curve: Curves.easeOut,
      builder: (_, v, ch) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 20 * (1 - v)), child: ch)),
      child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(
        color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 4))],
      ), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Voice Command Detected', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        Row(children: [
          Flexible(child: Text(cmd.exerciseName ?? 'Unknown Exercise',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
          if (cmd.exerciseName != null) ...[const SizedBox(width: 6), const Icon(Icons.check_circle, color: Colors.green, size: 16)],
          const Spacer(),
          GestureDetector(onTap: _onChange, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: const Text('Change', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
          )),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _Chip(label: 'Reps', value: '${cmd.reps}'),
          if (cmd.weight != null) ...[const SizedBox(width: 16), _Chip(label: 'Weight', value: '${cmd.weight!.toStringAsFixed(1)} kg')],
        ]),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: _isConfirming ? null : _onConfirm,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.blue.withValues(alpha: 0.5), disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
            padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: Text(_isConfirming ? 'Logging...' : 'Confirm & Log',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        )),
      ])),
    ));
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 11, color: t.colorScheme.onSurfaceVariant)),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    ]);
  }
}
