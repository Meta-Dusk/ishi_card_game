part of 'card_aura.dart';

extension CardEffects on CardAura {
  Animate get fireEffect => child
      .animate(onPlay: (controller) => controller.repeat(reverse: true))
      .boxShadow(
        begin: const BoxShadow(color: Colors.transparent),
        end: BoxShadow(
          color: Colors.redAccent,
          blurRadius: 15,
          spreadRadius: 5,
        ),
        duration: 800.ms,
      )
      .tint(color: Colors.orange.withValues(alpha: 0.2), duration: 800.ms);

  Animate get freezeEffect => child
      .animate(onPlay: (controller) => controller.repeat(reverse: true))
      .boxShadow(
        begin: const BoxShadow(color: Colors.transparent),
        end: BoxShadow(
          color: Colors.blueAccent,
          blurRadius: 15,
          spreadRadius: 5,
        ),
        duration: 800.ms,
      )
      .tint(
        color: Colors.lightBlueAccent.withValues(alpha: 0.2),
        duration: 800.ms,
      );

  Animate get natureSkipEffect => child
      .animate(onPlay: (controller) => controller.repeat(reverse: true))
      .boxShadow(
        begin: const BoxShadow(color: Colors.transparent),
        end: BoxShadow(
          color: Colors.greenAccent,
          blurRadius: 15,
          spreadRadius: 5,
        ),
        duration: 800.ms,
      )
      .tint(
        color: Colors.lightGreenAccent.withValues(alpha: 0.2),
        duration: 800.ms,
      );

  Animate get wildDoubleApEffect => child
      .animate(onPlay: (controller) => controller.repeat(reverse: true))
      .boxShadow(
        begin: const BoxShadow(color: Colors.transparent),
        end: BoxShadow(
          color: Colors.deepPurple,
          blurRadius: 15,
          spreadRadius: 5,
        ),
        duration: 800.ms,
      )
      .tint(
        color: Colors.deepPurpleAccent.withValues(alpha: 0.2),
        duration: 800.ms,
      );

  DeterministicEffectConfiguration get fireEffectConfig => _fireEffectConfig;

  DeterministicEffectConfiguration get iceEffectConfig => _iceEffectConfig;

  DeterministicEffectConfiguration get natureEffectConfig =>
      _natureEffectConfig;

  static final _fireEffectConfig = DeterministicEffectConfiguration(
    deterministicProperties: DeterministicProperties(
      distance: .single(100.0),
      angle: .between(-130.0, -30.0),
    ),
    visualProperties: VisualProperties(
      beginScale: .between(0.0, 1.0),
      fadeInThreshold: .between(0.1, 0.4),
      fadeOutThreshold: .between(0.1, 0.3),
    ),
    emissionProperties: EmissionProperties(
      particlesPerEmit: 2,
      origin: Offset(0.4, 0.9),
      minOriginOffset: .zero,
      maxOriginOffset: Offset(0.2, 0.05),
    ),
    particleConfiguration: ParticleConfiguration(
      shape: CircleShape(),
      size: .square(100.0),
      color: LinearInterpolationParticleColor(
        colors: [
          Colors.orange.withValues(alpha: 0.6),
          Colors.yellow.shade900.withValues(alpha: 0.65),
          Colors.red.withValues(alpha: 0.7),
          Colors.red.shade900.withValues(alpha: 0.75),
        ],
      ),
    ),
    layerProperties: LayerProperties(particleLayer: .foreground),
  );

  static final _iceEffectConfig = DeterministicEffectConfiguration(
    deterministicProperties: DeterministicProperties(
      distance: .single(100.0),
      angle: .between(-180.0, 0.0),
    ),
    visualProperties: VisualProperties(
      beginScale: .between(0.5, 1.5),
      endScale: .between(-1.0, 0.3),
      fadeInThreshold: .between(0.0, 1.0),
      fadeOutThreshold: .between(0.0, 1.0),
    ),
    emissionProperties: EmissionProperties(
      emitDuration: Duration(milliseconds: 310),
      origin: Offset(0.2, 0.9),
      minOriginOffset: .zero,
      maxOriginOffset: Offset(0.6, 0.1),
      particleLifespan: .single(Duration(seconds: 10)),
    ),
    layerProperties: LayerProperties(
      particleLayer: .foreground,
      trail: StraightTrail(trailProgress: 1.0, trailWidth: 10.0),
    ),
    particleConfiguration: ParticleConfiguration(
      shape: CircleShape(),
      size: .square(1.0),
      color: LinearInterpolationParticleColor(
        colors: [
          Colors.blue,
          Colors.blueAccent,
          Colors.lightBlue.withValues(alpha: 0.5),
          Colors.lightBlueAccent.withValues(alpha: 0.5),
        ],
      ),
    ),
  );

  static final _natureEffectConfig = DeterministicEffectConfiguration(
    deterministicProperties: DeterministicProperties(
      distance: .single(80.0),
      angle: .between(-180.0, 0.0),
    ),
    visualProperties: VisualProperties(
      beginScale: .between(0.5, 1.5),
      endScale: .between(-1.0, 0.3),
      fadeInThreshold: .between(0.0, 1.0),
      fadeOutThreshold: .between(0.0, 1.0),
    ),
    emissionProperties: EmissionProperties(
      emitDuration: Duration(milliseconds: 310),
      origin: Offset(0.15, 0.9),
      minOriginOffset: .zero,
      maxOriginOffset: Offset(0.75, 0.1),
      particleLifespan: .single(Duration(seconds: 10)),
    ),
    layerProperties: LayerProperties(
      particleLayer: .foreground,
      trail: StraightTrail(trailProgress: 1.0, trailWidth: 10.0),
    ),
    particleConfiguration: ParticleConfiguration(
      shape: CircleShape(),
      size: .square(1.0),
      color: LinearInterpolationParticleColor(
        colors: [
          Colors.green,
          Colors.greenAccent,
          Colors.lightGreen.withValues(alpha: 0.5),
          Colors.lightGreenAccent.withValues(alpha: 0.5),
        ],
      ),
    ),
  );
}
