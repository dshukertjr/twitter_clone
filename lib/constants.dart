import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const listPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 16);

const spacer = SizedBox(
  height: 20,
  width: 20,
);

const preloader = Center(child: CircularProgressIndicator());

final supabase = Supabase.instance.client;
