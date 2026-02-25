# 3D 카툰 돌(Stone) 씬 구성

3D 절차 생성 + 카툰 셰이더 + 2D 위젯 표시 파이프라인 사용 방법.

## 파일 구성

| 파일 | 역할 |
|------|------|
| `scripts/StonePrng.gd` | 엔진 독립 LCG 난수 (동일 시드 → 동일 형태) |
| `toon_crystal.gdshader` | 3D 툰 셰이더 (3단 명암, 입도·탁도) |
| `outline.gdshader` | 만화 외곽선 (cull_front + NORMAL 확장) |
| `stone_3d.gd` | Node3D 절차 생성 (결정계·군집·매터리얼) |
| `stone_widget.gd` | Control 루트, `apply_stone_data`를 StoneRoot에 전달 |
| `Stone3D.tscn` | SubViewport + Camera3D + Light + StoneRoot 씬 |

## 메인 씬에서 2D 돌을 3D 돌로 바꾸기

1. `main.tscn`을 연다.
2. 기존 **Stone** 노드(RigidBody2D)를 삭제한다.
3. **Stone3D.tscn**을 드래그해 Main 아래에 넣고, 인스턴스 이름을 **Stone**으로 둔다.
4. Stone 노드에서 **신호 연결**: `input_event` → Main `_on_stone_input_event` (기존과 동일).
5. Stone(Control) 위치를 기존과 맞춘다 (예: position = (576, 324)).

이후 `Main.gd`의 `stone.apply_stone_data(stone_data)` 호출은 그대로 두면 되며,  
Stone 위젯이 SubViewport 안의 3D 돌을 렌더링해 2D처럼 보이게 한다.

## SubViewport 설정 요약

- **SubViewport**: `transparent_bg` = On, `size` = 256×256 (필요 시 조정).
- **Camera3D**: `projection` = Orthogonal, 위치/거리로 돌이 잘리지 않게 조정.
- **DirectionalLight3D**: 회전으로 그림자 방향 조정.

## PRD 반영

- **11.1** 결정계 → shape_type (0 큐브, 1 육각기둥, 2 판상, 3 괴상).
- **11.1** 온도 → 군집 개수·퍼짐, 입도(세립/조립).
- **9.2** 전이 금속 발색 매트릭스, 탁도(cloudiness).
- **10.3** 자체 PRNG(StonePRNG)로 시드 고정.
