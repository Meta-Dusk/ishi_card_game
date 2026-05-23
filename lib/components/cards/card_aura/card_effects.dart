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

  Animate get natureEffect => child
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

  Animate get unfluxEffect => child
      .animate(onPlay: (controller) => controller.repeat(reverse: true))
      .boxShadow(
        begin: const BoxShadow(color: Colors.transparent),
        end: BoxShadow(color: Colors.yellow, blurRadius: 15, spreadRadius: 5),
        duration: 800.ms,
      )
      .tint(
        color: Colors.yellowAccent.withValues(alpha: 0.2),
        duration: 800.ms,
      );

  Animate get unfluxEffectAmp => child
      .animate(onPlay: (controller) => controller.repeat(reverse: true))
      .boxShadow(
        begin: BoxShadow(
          color: Colors.yellow.withValues(alpha: 0.35),
          blurRadius: 15,
          spreadRadius: 5,
        ),
        end: BoxShadow(color: Colors.yellow, blurRadius: 15, spreadRadius: 5),
        duration: 200.ms,
      )
      .tint(color: Colors.yellowAccent.withValues(alpha: 0.2), duration: 200.ms)
      .shake(
        delay: 300.ms,
        duration: 100.ms,
        curve: Curves.easeInOutQuint,
        offset: Offset(0.5, 0.5),
        rotation: 0.1,
      );

  Animate get wildDoubleTroubleEffect => child
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
    deterministicProperties: const DeterministicProperties(
      distance: .single(100.0),
      angle: .between(-130.0, -30.0),
    ),
    visualProperties: const VisualProperties(
      beginScale: .between(0.0, 1.0),
      fadeInThreshold: .between(0.1, 0.4),
      fadeOutThreshold: .between(0.1, 0.3),
    ),
    emissionProperties: const EmissionProperties(
      particlesPerEmit: 2,
      origin: Offset(0.4, 0.9),
      minOriginOffset: .zero,
      maxOriginOffset: Offset(0.2, 0.05),
    ),
    particleConfiguration: ParticleConfiguration(
      shape: const CircleShape(),
      size: const .square(100.0),
      color: LinearInterpolationParticleColor(
        colors: [
          Colors.orange.withValues(alpha: 0.6),
          Colors.yellow.shade900.withValues(alpha: 0.65),
          Colors.red.withValues(alpha: 0.7),
          Colors.red.shade900.withValues(alpha: 0.75),
        ],
      ),
    ),
    layerProperties: const LayerProperties(particleLayer: .foreground),
  );

  static final _iceEffectConfig = DeterministicEffectConfiguration(
    deterministicProperties: const DeterministicProperties(
      distance: NumRange.single(180),
      angle: NumRange.single(90),
    ),
    visualProperties: const VisualProperties(
      beginScale: NumRange.between(0.5, 1.0),
    ),
    layerProperties: const LayerProperties(particleLayer: .foreground),
    emissionProperties: const EmissionProperties(
      origin: Offset.zero,
      maxOriginOffset: Offset(1, 0),
      particleLifespan: DurationRange.between(
        Duration(seconds: 4),
        Duration(seconds: 7),
      ),
    ),
    particleConfiguration: ParticleConfiguration(
      shape: ImageAssetShape(AppAssets.particles.snowflake),
      size: const .square(25),
      color: LinearInterpolationParticleColor(
        colors: [
          Colors.white.withValues(alpha: 0.4),
          Colors.white.withValues(alpha: 0.2),
          Colors.white.withValues(alpha: 0.1),
        ],
      ),
    ),
  );

  static final _natureEffectConfig = DeterministicEffectConfiguration(
    deterministicProperties: const DeterministicProperties(
      distance: .single(180),
      angle: .single(90),
    ),
    visualProperties: const VisualProperties(
      endScale: .single(1),
      fadeOutThreshold: .between(0.6, 0.8),
    ),
    layerProperties: const LayerProperties(particleLayer: .foreground),
    emissionProperties: const EmissionProperties(
      origin: Offset.zero,
      maxOriginOffset: Offset(1, 0),
      particleLifespan: DurationRange.between(
        Duration(seconds: 4),
        Duration(seconds: 7),
      ),
    ),
    particleConfiguration: ParticleConfiguration(
      shape: CircleShape(),
      size: const .square(5),
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
