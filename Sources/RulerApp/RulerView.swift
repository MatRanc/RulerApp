import AppKit
import SwiftUI

struct RulerView: View {
    let state: RulerState
    let onCalibrate: () -> Void

    var body: some View {
        let ppm = state.pointsPerMm
        let unit = state.unit
        let gridMode = state.gridMode

        ZStack(alignment: .topLeading) {
            Canvas { context, size in
                drawGrid(into: &context, size: size, pointsPerMm: ppm, unit: unit, mode: gridMode)
                drawRulers(into: &context, size: size, pointsPerMm: ppm, unit: unit)
            }
            .background(Color(nsColor: .windowBackgroundColor))
            .onContinuousHover { phase in
                switch phase {
                case .active(let p): state.cursorLocal = p
                case .ended: state.cursorLocal = nil
                }
            }

            cursorBadge(pointsPerMm: ppm, unit: unit)

            controls
                .padding(8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
    }

    // MARK: - Cursor badge

    @ViewBuilder
    private func cursorBadge(pointsPerMm ppm: CGFloat, unit: RulerUnit) -> some View {
        if let local = state.cursorLocal {
            let xMm = local.x / ppm
            let yMm = local.y / ppm
            VStack(alignment: .leading, spacing: 2) {
                Text("X: \(RulerFormat.format(mm: xMm, unit: unit))")
                Text("Y: \(RulerFormat.format(mm: yMm, unit: unit))")
            }
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.black.opacity(0.75))
            )
            .fixedSize()
            .offset(x: local.x + 14, y: local.y + 14)
            .allowsHitTesting(false)
        }
    }

    // MARK: - Controls strip

    private var gridButtonLabel: String {
        switch state.gridMode {
        case .off: return "Grid"
        case .major: return "Grid •"
        case .majorAndMinor: return "Grid ••"
        }
    }

    private var controls: some View {
        HStack(spacing: 6) {
            Button(state.unit.label) { state.unit = state.unit.next }
                .help("Toggle unit (U)")
            Button(gridButtonLabel) { state.gridMode = state.gridMode.next }
                .help("Cycle grid: off → major → major + minor (G)")
            Button("Calibrate") { onCalibrate() }
                .help("Recalibrate this display (C)")
        }
        .controlSize(.small)
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(.regularMaterial)
        )
    }

    // MARK: - Tick drawing

    private func drawRulers(into context: inout GraphicsContext, size: CGSize, pointsPerMm ppm: CGFloat, unit: RulerUnit) {
        switch unit {
        case .mmcm:
            drawMetricTop(into: &context, width: size.width, ppm: ppm, yOffset: 0)
            drawMetricLeft(into: &context, height: size.height, ppm: ppm, xOffset: 0)
        case .inches:
            drawImperialTop(into: &context, width: size.width, ppm: ppm, yOffset: 0)
            drawImperialLeft(into: &context, height: size.height, ppm: ppm, xOffset: 0)
        case .both:
            drawMetricTop(into: &context, width: size.width, ppm: ppm, yOffset: 0)
            drawImperialTop(into: &context, width: size.width, ppm: ppm, yOffset: 22)
            drawMetricLeft(into: &context, height: size.height, ppm: ppm, xOffset: 0)
            drawImperialLeft(into: &context, height: size.height, ppm: ppm, xOffset: 22)
        }
    }

    // MARK: Metric

    private func drawMetricTop(into context: inout GraphicsContext, width: CGFloat, ppm: CGFloat, yOffset: CGFloat) {
        let totalMm = Int(floor(width / ppm))
        for mm in 0...totalMm {
            let x = CGFloat(mm) * ppm
            let length = metricTickLength(forMm: mm)
            var path = Path()
            path.move(to: CGPoint(x: x, y: yOffset))
            path.addLine(to: CGPoint(x: x, y: yOffset + length))
            stroke(path, into: &context)

            if mm > 0, mm % 10 == 0 {
                drawLabel(String(mm / 10), at: CGPoint(x: x + 3, y: yOffset + length + 1), into: &context)
            }
        }
    }

    private func drawMetricLeft(into context: inout GraphicsContext, height: CGFloat, ppm: CGFloat, xOffset: CGFloat) {
        let totalMm = Int(floor(height / ppm))
        for mm in 0...totalMm {
            let y = CGFloat(mm) * ppm
            let length = metricTickLength(forMm: mm)
            var path = Path()
            path.move(to: CGPoint(x: xOffset, y: y))
            path.addLine(to: CGPoint(x: xOffset + length, y: y))
            stroke(path, into: &context)

            if mm > 0, mm % 10 == 0 {
                drawLabel(String(mm / 10), at: CGPoint(x: xOffset + length + 2, y: y + 1), into: &context)
            }
        }
    }

    private func metricTickLength(forMm mm: Int) -> CGFloat {
        if mm % 10 == 0 { return 14 }
        if mm % 5 == 0 { return 9 }
        return 4
    }

    // MARK: Imperial

    private func drawImperialTop(into context: inout GraphicsContext, width: CGFloat, ppm: CGFloat, yOffset: CGFloat) {
        let step = ppm * 25.4 / 16
        let total = Int(floor(width / step))
        for s in 0...total {
            let x = CGFloat(s) * step
            let length = imperialTickLength(forSixteenths: s)
            var path = Path()
            path.move(to: CGPoint(x: x, y: yOffset))
            path.addLine(to: CGPoint(x: x, y: yOffset + length))
            stroke(path, into: &context)

            if s > 0, s % 16 == 0 {
                drawLabel(String(s / 16), at: CGPoint(x: x + 3, y: yOffset + length + 1), into: &context)
            }
        }
    }

    private func drawImperialLeft(into context: inout GraphicsContext, height: CGFloat, ppm: CGFloat, xOffset: CGFloat) {
        let step = ppm * 25.4 / 16
        let total = Int(floor(height / step))
        for s in 0...total {
            let y = CGFloat(s) * step
            let length = imperialTickLength(forSixteenths: s)
            var path = Path()
            path.move(to: CGPoint(x: xOffset, y: y))
            path.addLine(to: CGPoint(x: xOffset + length, y: y))
            stroke(path, into: &context)

            if s > 0, s % 16 == 0 {
                drawLabel(String(s / 16), at: CGPoint(x: xOffset + length + 2, y: y + 1), into: &context)
            }
        }
    }

    private func imperialTickLength(forSixteenths s: Int) -> CGFloat {
        if s % 16 == 0 { return 14 }
        if s % 8 == 0 { return 11 }
        if s % 4 == 0 { return 8 }
        if s % 2 == 0 { return 5 }
        return 3
    }

    // MARK: Grid

    private func drawGrid(into context: inout GraphicsContext, size: CGSize, pointsPerMm ppm: CGFloat, unit: RulerUnit, mode: RulerGridMode) {
        guard mode.showsMajor else { return }

        let (majorStep, minorStep): (CGFloat, CGFloat) = {
            switch unit {
            case .inches:
                let inch = ppm * 25.4
                return (inch, inch / 8)            // 1" major, 1/8" minor
            case .mmcm, .both:
                return (10 * ppm, ppm)             // 10mm major, 1mm minor
            }
        }()

        if mode.showsMinor {
            drawGridLines(
                into: &context,
                size: size,
                step: minorStep,
                shading: .color(.secondary.opacity(0.15)),
                lineWidth: 0.5
            )
        }

        drawGridLines(
            into: &context,
            size: size,
            step: majorStep,
            shading: .color(.secondary.opacity(0.4)),
            lineWidth: 0.5
        )
    }

    private func drawGridLines(into context: inout GraphicsContext, size: CGSize, step: CGFloat, shading: GraphicsContext.Shading, lineWidth: CGFloat) {
        var v = step
        while v < size.width {
            var path = Path()
            path.move(to: CGPoint(x: v, y: 0))
            path.addLine(to: CGPoint(x: v, y: size.height))
            context.stroke(path, with: shading, lineWidth: lineWidth)
            v += step
        }
        var h = step
        while h < size.height {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: h))
            path.addLine(to: CGPoint(x: size.width, y: h))
            context.stroke(path, with: shading, lineWidth: lineWidth)
            h += step
        }
    }

    // MARK: Drawing helpers

    private func stroke(_ path: Path, into context: inout GraphicsContext) {
        context.stroke(path, with: .color(.primary), lineWidth: 1)
    }

    private func drawLabel(_ text: String, at point: CGPoint, into context: inout GraphicsContext) {
        let styled = Text(text)
            .font(.system(size: 9, weight: .medium, design: .monospaced))
            .foregroundColor(.primary)
        let resolved = context.resolve(styled)
        context.draw(resolved, at: point, anchor: .topLeading)
    }
}
