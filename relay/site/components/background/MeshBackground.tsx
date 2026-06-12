"use client";

import { useEffect, useRef } from "react";
import { Renderer, Program, Mesh, Triangle } from "ogl";

const vert = /* glsl */ `
  attribute vec2 position;
  varying vec2 vUv;
  void main() {
    vUv = position * 0.5 + 0.5;
    gl_Position = vec4(position, 0.0, 1.0);
  }
`;

const frag = /* glsl */ `
  precision highp float;
  varying vec2 vUv;
  uniform float uTime;
  uniform vec2 uResolution;

  void main() {
    vec2 uv = vUv;
    vec2 p = (uv - 0.5) * vec2(uResolution.x / uResolution.y, 1.0);

    float t = uTime * 0.15;
    float a = sin(p.x * 2.0 + t) * 0.08 + cos(p.y * 2.5 - t * 0.8) * 0.08;
    float b = sin(length(p + vec2(sin(t)*0.2, cos(t)*0.15)) * 4.0 - t) * 0.5 + 0.5;

    vec3 c1 = vec3(0.04, 0.06, 0.12);
    vec3 c2 = vec3(0.08, 0.12, 0.22);
    vec3 accent = vec3(0.15, 0.35, 0.55) * b * 0.35;
    vec3 col = mix(c1, c2, uv.y + a);
    col += accent;

    gl_FragColor = vec4(col, 1.0);
  }
`;

export function MeshBackground() {
  const ref = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = ref.current;
    if (!canvas) return;

    const renderer = new Renderer({ canvas, alpha: false, dpr: Math.min(window.devicePixelRatio, 1.5) });
    const gl = renderer.gl;
    const geometry = new Triangle(gl);
    const program = new Program(gl, { vertex: vert, fragment: frag, uniforms: { uTime: { value: 0 }, uResolution: { value: [1, 1] } } });
    const mesh = new Mesh(gl, { geometry, program });

    let raf = 0;
    let start = performance.now();

    const resize = () => {
      renderer.setSize(window.innerWidth, window.innerHeight);
      program.uniforms.uResolution.value = [gl.drawingBufferWidth, gl.drawingBufferHeight];
    };
    resize();
    window.addEventListener("resize", resize);

    const loop = (now: number) => {
      program.uniforms.uTime.value = (now - start) * 0.001;
      renderer.render({ scene: mesh });
      raf = requestAnimationFrame(loop);
    };
    raf = requestAnimationFrame(loop);

    return () => {
      cancelAnimationFrame(raf);
      window.removeEventListener("resize", resize);
    };
  }, []);

  return <canvas ref={ref} className="mesh-bg pointer-events-none fixed inset-0 z-0" aria-hidden />;
}
