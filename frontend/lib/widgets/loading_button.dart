import 'package:flutter/material.dart';

/// A button that shows a loading spinner and disables itself while the
/// provided async `onPressed` is running. Defaults to an ElevatedButton
/// style; pass a custom `style` to adjust appearance.
class LoadingButton extends StatefulWidget {
  final Future<void> Function()? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool enabled;

  const LoadingButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.style,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<LoadingButton> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton> {
  bool _loading = false;

  Future<void> _handlePressed() async {
    if (widget.onPressed == null) return;
    setState(() => _loading = true);
    try {
      await widget.onPressed!();
    } catch (e) {
      rethrow;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabled = !widget.enabled || widget.onPressed == null || _loading;

    return ElevatedButton(
      onPressed: disabled ? null : _handlePressed,
      style: widget.style,
      child: _loading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.onPrimary),
              ),
            )
          : widget.child,
    );
  }
}
