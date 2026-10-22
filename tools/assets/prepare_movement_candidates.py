"""Optional gait comparison fixture. Not a production asset. Run before measure_movement_candidates.gd."""
from pathlib import Path
import prepare_3d as pipeline

data,binary=pipeline.read(pipeline.ROOT/'art/models/goblin.glb')
pipeline.merge_clips(data,binary,pipeline.locate('kaykit-character-animations','Rig_Medium_MovementBasic.glb'),{'Walking_B':'walk_b','Walking_C':'walk_c','Running_B':'run_b'})
pipeline.write(pipeline.ROOT/'art/models/qa_movement.glb',data,binary)
print('QA gait model ready; remove qa_movement.glb and its import descriptor after comparison.')
