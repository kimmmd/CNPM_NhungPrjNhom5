"""Mô phỏng xúc xắc 8051 và thuật toán lấy số từ Timer0."""

from __future__ import annotations

import argparse
import csv
import random
import sys
from collections import Counter
from pathlib import Path
from typing import Optional, Sequence


FACE_COUNT = 6
TL0_LIMIT = 252
COLORS = {
    "asm": "#2e8b57",
    "raw": "#377eb8",
    "samples": "#e68632",
    "grid": "#d9dee7",
    "text": "#253047",
}
SEGMENTS = {
    0: "abcdef",
    1: "bc",
    2: "abged",
    3: "abgcd",
    4: "fgbc",
    5: "afgcd",
    6: "afgecd",
    7: "abc",
    "-": "g",
}


def random_raw(rng: random.Random) -> int:
    """Mô phỏng bản thô: lấy một byte TL0 rồi tính (TL0 mod 6) + 1."""
    return rng.randrange(256) % FACE_COUNT + 1


def random_asm(rng: random.Random) -> int:
    """Mô phỏng GET_RANDOM: bỏ TL0 >= 252 rồi tính (TL0 mod 6) + 1."""
    while True:
        tl0 = rng.randrange(256)
        if tl0 < TL0_LIMIT:
            return tl0 % FACE_COUNT + 1


def simulate(trials: int, seed: Optional[int] = None) -> tuple[Counter, Counter]:
    if trials < 1:
        raise ValueError("Số lượt mô phỏng phải lớn hơn 0.")

    rng = random.Random(seed)
    asm_counts: Counter = Counter()
    raw_counts: Counter = Counter()
    for _ in range(trials):
        asm_counts[random_asm(rng)] += 1
        raw_counts[random_raw(rng)] += 1
    return asm_counts, raw_counts


def theoretical_probabilities() -> tuple[list[float], list[float]]:
    """Trả về xác suất theo thứ tự mặt 1..6 của ASM và bản thô."""
    asm = [1 / FACE_COUNT] * FACE_COUNT
    raw = [43 / 256] * 4 + [42 / 256] * 2
    return asm, raw


def parse_samples(path: Path) -> Counter:
    counts: Counter = Counter()
    with path.open("r", encoding="utf-8-sig", newline="") as sample_file:
        for row_number, row in enumerate(csv.reader(sample_file), start=1):
            for value in row:
                value = value.strip()
                if not value:
                    continue
                try:
                    face = int(value)
                except ValueError as error:
                    raise ValueError(
                        f"Dữ liệu mẫu dòng {row_number} không phải số nguyên: {value!r}."
                    ) from error
                if face < 1 or face > FACE_COUNT:
                    raise ValueError(
                        f"Dữ liệu mẫu dòng {row_number} nằm ngoài khoảng 1–6: {face}."
                    )
                counts[face] += 1

    if not counts:
        raise ValueError("File mẫu không có kết quả nào trong khoảng 1–6.")
    return counts


def print_report(
    trials: int,
    asm_counts: Counter,
    raw_counts: Counter,
    sample_counts: Optional[Counter] = None,
) -> None:
    asm_theory, raw_theory = theoretical_probabilities()
    print(f"Số lượt mô phỏng: {trials:,}")
    print("Mặt | ASM bỏ TL0 >= 252 | TL0 mod 6 thô")
    for face in range(1, FACE_COUNT + 1):
        asm_percent = asm_counts[face] * 100 / trials
        raw_percent = raw_counts[face] * 100 / trials
        print(
            f" {face}  | {asm_counts[face]:>8} ({asm_percent:6.3f}%; "
            f"lý thuyết {asm_theory[face - 1] * 100:6.3f}%)"
            f" | {raw_counts[face]:>8} ({raw_percent:6.3f}%; "
            f"lý thuyết {raw_theory[face - 1] * 100:6.3f}%)"
        )
    if sample_counts:
        total_samples = sum(sample_counts.values())
        print(f"\nKết quả SimulIDE: {total_samples} lần nhấn")
        for face in range(1, FACE_COUNT + 1):
            count = sample_counts[face]
            print(f" {face}: {count:>4} ({count * 100 / total_samples:6.2f}%)")


def launch_gui(
    trials: int,
    seed: Optional[int],
    sample_counts: Optional[Counter] = None,
) -> None:
    import tkinter as tk
    from tkinter import filedialog, messagebox, ttk

    class DiceApp:
        def __init__(self, root: tk.Tk) -> None:
            self.root = root
            self.root.title("Xúc xắc điện tử 8051")
            self.root.minsize(900, 570)
            self.root.configure(bg="#f4f6fa")
            self.rng = random.Random(seed)
            self.asm_counts: Counter = Counter()
            self.raw_counts: Counter = Counter()
            self.sample_counts = sample_counts
            self.is_spinning = False
            self.spin_step = 0
            self.spin_total = 20
            self.current_face = 1

            style = ttk.Style(root)
            style.configure("TFrame", background="#f4f6fa")
            style.configure("TLabel", background="#f4f6fa", foreground=COLORS["text"])
            style.configure("Title.TLabel", font=("Segoe UI", 16, "bold"))
            style.configure("Hint.TLabel", font=("Segoe UI", 9))
            style.configure("TButton", padding=(9, 5))

            outer = ttk.Frame(root, padding=16)
            outer.pack(fill="both", expand=True)
            ttk.Label(
                outer, text="Mô phỏng xúc xắc điện tử 8051", style="Title.TLabel"
            ).pack(anchor="w")
            ttk.Label(
                outer,
                text=(
                    "So sánh lấy TL0 thô với GET_RANDOM trong input.asm "
                    "(loại mẫu từ 252 đến 255)."
                ),
                style="Hint.TLabel",
            ).pack(anchor="w", pady=(2, 12))

            controls = ttk.Frame(outer)
            controls.pack(fill="x", pady=(0, 12))
            ttk.Label(controls, text="Số lượt:").pack(side="left")
            self.trials_var = tk.StringVar(value=str(trials))
            ttk.Entry(controls, textvariable=self.trials_var, width=10).pack(
                side="left", padx=(6, 12)
            )
            ttk.Button(controls, text="Chạy mô phỏng", command=self.run_simulation).pack(
                side="left"
            )
            ttk.Button(
                controls, text="Tải kết quả SimulIDE…", command=self.load_sample_file
            ).pack(side="left", padx=8)
            self.roll_button = ttk.Button(
                controls, text="Nhấn nút / gieo xúc xắc", command=self.start_roll
            )
            self.roll_button.pack(side="right")

            content = ttk.Frame(outer)
            content.pack(fill="both", expand=True)
            chart_frame = ttk.Frame(content)
            chart_frame.pack(side="left", fill="both", expand=True)
            self.chart = tk.Canvas(
                chart_frame,
                width=650,
                height=360,
                bg="white",
                highlightthickness=1,
                highlightbackground="#d9dee7",
            )
            self.chart.pack(fill="both", expand=True)
            self.chart.bind(
                "<Configure>",
                lambda event: self.draw_chart(event.width, event.height),
            )

            display_frame = ttk.Frame(content, padding=(16, 0, 0, 0))
            display_frame.pack(side="right", fill="y")
            ttk.Label(
                display_frame, text="LED 7 đoạn", font=("Segoe UI", 11, "bold")
            ).pack(pady=(0, 6))
            self.led = tk.Canvas(
                display_frame,
                width=180,
                height=225,
                bg="#17191e",
                highlightthickness=0,
            )
            self.led.pack()
            self.status_var = tk.StringVar(value="Chờ nhấn")
            ttk.Label(
                display_frame,
                textvariable=self.status_var,
                wraplength=180,
                justify="center",
            ).pack(pady=8)

            self.summary_var = tk.StringVar()
            ttk.Label(
                outer,
                textvariable=self.summary_var,
                justify="left",
                style="Hint.TLabel",
            ).pack(fill="x", pady=(12, 0))
            self.draw_led("-")
            self.run_simulation()

        def run_simulation(self) -> None:
            try:
                count = int(self.trials_var.get())
                if count < 1:
                    raise ValueError
            except ValueError:
                messagebox.showerror("Số lượt không hợp lệ", "Nhập số nguyên lớn hơn 0.")
                return

            self.asm_counts, self.raw_counts = simulate(count, self.rng.getrandbits(64))
            self.update_summary(count)
            self.draw_chart()

        def update_summary(self, count: int) -> None:
            asm_theory, raw_theory = theoretical_probabilities()
            lines = [
                f"ASM: bỏ 252–255 → mỗi mặt lý thuyết "
                f"{asm_theory[0] * 100:.3f}%.  "
                f"TL0 thô: mặt 1–4 = {raw_theory[0] * 100:.3f}%; "
                f"mặt 5–6 = {raw_theory[4] * 100:.3f}%.",
                f"Histogram đang chuẩn hóa theo phần trăm ({count:,} lượt).",
            ]
            if self.sample_counts:
                sample_total = sum(self.sample_counts.values())
                lines.append(
                    f"Mẫu SimulIDE: {sample_total} lần nhấn. "
                    "Nạp file CSV/văn bản gồm các số 1–6, phân cách bằng dấu phẩy "
                    "hoặc xuống dòng."
                )
            self.summary_var.set("\n".join(lines))

        def draw_chart(
            self, requested_width: Optional[int] = None, requested_height: Optional[int] = None
        ) -> None:
            canvas = self.chart
            canvas.delete("all")
            width = max(requested_width or canvas.winfo_width(), 400)
            height = max(requested_height or canvas.winfo_height(), 280)
            left, right, top, bottom = 52, 18, 30, 58
            plot_width = width - left - right
            plot_height = height - top - bottom
            max_percent = 25.0
            for tick in range(0, 26, 5):
                y = top + plot_height * (1 - tick / max_percent)
                canvas.create_line(left, y, width - right, y, fill=COLORS["grid"])
                canvas.create_text(
                    left - 8,
                    y,
                    text=f"{tick}%",
                    anchor="e",
                    fill=COLORS["text"],
                    font=("Segoe UI", 8),
                )

            sources = [
                ("ASM bỏ ≥252", self.asm_counts, COLORS["asm"]),
                ("TL0 mod 6 thô", self.raw_counts, COLORS["raw"]),
            ]
            if self.sample_counts:
                sources.append(
                    ("SimulIDE", self.sample_counts, COLORS["samples"])
                )
            group_width = plot_width / FACE_COUNT
            bar_group_width = group_width * 0.72
            bar_width = bar_group_width / len(sources)

            for index, face in enumerate(range(1, FACE_COUNT + 1)):
                group_x = left + index * group_width
                for source_index, source in enumerate(sources):
                    counts = source[1]
                    color = source[2]
                    total = sum(counts.values())
                    percent = counts[face] * 100 / total if total else 0
                    bar_height = min(percent, max_percent) / max_percent * plot_height
                    x = (
                        group_x
                        + (group_width - bar_group_width) / 2
                        + source_index * bar_width
                    )
                    y = top + plot_height - bar_height
                    canvas.create_rectangle(
                        x + 1,
                        y,
                        x + bar_width - 2,
                        top + plot_height,
                        fill=color,
                        outline="",
                    )
                canvas.create_text(
                    group_x + group_width / 2,
                    top + plot_height + 17,
                    text=str(face),
                    fill=COLORS["text"],
                    font=("Segoe UI", 9),
                )

            canvas.create_text(
                left + plot_width / 2,
                height - 12,
                text="Mặt xúc xắc",
                fill=COLORS["text"],
                font=("Segoe UI", 9),
            )
            legend_x = left
            for source in sources:
                label = source[0]
                color = source[2]
                canvas.create_rectangle(
                    legend_x, 8, legend_x + 12, 20, fill=color, outline=""
                )
                canvas.create_text(
                    legend_x + 17,
                    14,
                    text=label,
                    anchor="w",
                    fill=COLORS["text"],
                    font=("Segoe UI", 8),
                )
                legend_x += 142 if len(sources) == 2 else 120

        def draw_led(self, face: object) -> None:
            self.led.delete("all")
            active = SEGMENTS.get(face, "")
            coordinates = {
                "a": (48, 24, 132, 24, 122, 34, 58, 34),
                "b": (134, 28, 144, 38, 144, 98, 134, 108),
                "c": (134, 117, 144, 127, 144, 187, 134, 197),
                "d": (48, 201, 132, 201, 122, 191, 58, 191),
                "e": (36, 117, 46, 127, 46, 187, 36, 197),
                "f": (36, 28, 46, 38, 46, 98, 36, 108),
                "g": (48, 112, 58, 102, 122, 102, 132, 112, 122, 122, 58, 122),
            }
            for segment, points in coordinates.items():
                self.led.create_polygon(
                    points,
                    fill="#ff342e" if segment in active else "#47201f",
                    outline="",
                )
            shown = face if isinstance(face, int) else "-"
            self.led.create_text(
                90,
                215,
                text=f"P1.0–P1.6  |  {shown}",
                fill="#c6c9d0",
                font=("Segoe UI", 8),
            )

        def load_sample_file(self) -> None:
            filename = filedialog.askopenfilename(
                title="Chọn file kết quả SimulIDE",
                filetypes=(
                    ("CSV hoặc văn bản", "*.csv *.txt"),
                    ("Tất cả tệp", "*.*"),
                ),
            )
            if not filename:
                return
            try:
                self.sample_counts = parse_samples(Path(filename))
            except (OSError, ValueError) as error:
                messagebox.showerror("Không đọc được dữ liệu", str(error))
                return
            self.update_summary(sum(self.asm_counts.values()))
            self.draw_chart()

        def start_roll(self) -> None:
            if self.is_spinning:
                return
            self.is_spinning = True
            self.roll_button.state(["disabled"])
            self.spin_step = 0
            self.spin_total = self.rng.randint(18, 24)
            self.current_face = self.rng.randint(1, FACE_COUNT)
            self.status_var.set("Đang quay…")
            self.spin_tick()

        def spin_tick(self) -> None:
            if self.spin_step >= self.spin_total:
                result = random_asm(self.rng)
                self.draw_led(result)
                self.status_var.set(f"Kết quả: {result}  ·  giữ 3 giây")
                self.root.after(3000, self.finish_roll)
                return

            self.current_face = self.current_face % FACE_COUNT + 1
            self.draw_led(self.current_face)
            self.spin_step += 1
            progress = self.spin_step / self.spin_total
            delay_ms = int(45 + 360 * progress**2)
            self.root.after(delay_ms, self.spin_tick)

        def finish_roll(self) -> None:
            self.draw_led("-")
            self.status_var.set("Chờ nhấn")
            self.is_spinning = False
            self.roll_button.state(["!disabled"])

    root = tk.Tk()
    DiceApp(root)
    root.mainloop()


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="So sánh mô phỏng random TL0 cho xúc xắc 8051."
    )
    parser.add_argument(
        "--trials",
        type=int,
        default=100_000,
        help="số lượt mô phỏng (mặc định: 100000)",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=None,
        help="seed để lặp lại cùng một mô phỏng",
    )
    parser.add_argument(
        "--samples",
        type=Path,
        help="file CSV/văn bản kết quả SimulIDE, chứa các mặt 1–6",
    )
    parser.add_argument(
        "--no-gui",
        action="store_true",
        help="chỉ in bảng thống kê, không mở giao diện",
    )
    return parser


def main(argv: Optional[Sequence[str]] = None) -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    if hasattr(sys.stderr, "reconfigure"):
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    parser = build_parser()
    args = parser.parse_args(argv)
    if args.trials < 1:
        parser.error("--trials phải lớn hơn 0.")

    try:
        sample_counts = parse_samples(args.samples) if args.samples else None
    except (OSError, ValueError) as error:
        parser.error(str(error))

    asm_counts, raw_counts = simulate(args.trials, args.seed)
    if args.no_gui:
        print_report(args.trials, asm_counts, raw_counts, sample_counts)
        return 0

    try:
        launch_gui(args.trials, args.seed, sample_counts)
    except ImportError as error:
        print(
            f"Không mở được giao diện Tkinter: {error}\n"
            "Hãy chạy lại với --no-gui để xem bảng kết quả.",
            file=sys.stderr,
        )
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())