part of '../main.dart';

/// Ownership dello stato PR-03 separata dal runtime generico.
mixin _Pr03ControllerOwner on State<ObjectRuntimePage> {
  late final Pr03Controller _pr03Controller = Pr03Controller();
}
