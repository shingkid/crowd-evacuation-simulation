globals [
  blue-escapees
  cyan-escapees
  yellow-escapees
  red-escapees
  beige-escapees
  green-escapees
  blue-fire-deaths
  cyan-fire-deaths
  yellow-fire-deaths
  red-fire-deaths
  beige-fire-deaths
  green-fire-deaths
  blue-stampede-deaths
  cyan-stampede-deaths
  yellow-stampede-deaths
  red-stampede-deaths
  beige-stampede-deaths
  green-stampede-deaths
  female-escapees
  female-fire-deaths
  female-stampede-deaths
  male-escapees
  male-fire-deaths
  male-stampede-deaths
  child-escapees
  child-fire-deaths
  child-stampede-deaths
  adult-escapees
  adult-fire-deaths
  adult-stampede-deaths
  elderly-escapees
  elderly-fire-deaths
  elderly-stampede-deaths
  oldgoal
]
breed [survivors survivor]
breed[doors door]
patches-own [
  distance1
  distance2
  distance3
  distance4
  distance5
  distance6
  distance7
  distance8
  distance9
  distance10
  distancefire
]

survivors-own [
  goal
  health
  base-speed
  speed  ; impacted by status and patch pressure (sum surrounding patch pressure)
  vision
  gender
  age
  mass
  panic
;  reaction-time
;  collaboration
;  insistence
  knowledge
]

to setup
  ca
  setup-stadium
  ;create 10 exits
  let door-xlist [-127 -87 -70 -49 -33 27 44 65 82 122]
  (foreach door-xlist[ [x] ->
     create-doors 1 [setxy x 21 set shape "square" set color lime set heading 180 set size 2]
    ])

  ask patches [set distance1 [distance myself] of door 14178]
  ask patches [set distance2 [distance myself] of door 14179]
  ask patches [set distance3 [distance myself] of door 14180]
  ask patches [set distance4 [distance myself] of door 14181]
  ask patches [set distance5 [distance myself] of door 14182]
  ask patches [set distance6 [distance myself] of door 14183]
  ask patches [set distance7 [distance myself] of door 14184]
  ask patches [set distance8 [distance myself] of door 14185]
  ask patches [set distance9 [distance myself] of door 14186]
  ask patches [set distance10 [distance myself] of door 14187]
  ;set goal
  ask survivors[
    set goal min-one-of doors [distance myself]
  ]
  set-survivors-attributes
  ; Start fire
  let origin patch 0 135
  if random-fire? [
    set origin patch random-xcor random-ycor
    while [ [ pcolor ] of origin = black ] [
      set origin one-of patches
    ]
  ]
  ask origin [
    draw-rectangle pxcor pycor 5 5 orange
  ]
  ask patches [set distancefire distancexy 0 135]

  reset-ticks
end

to go
  spread-fire
  ;ask patches [set distancefire min [distance myself] of patches with  [pcolor = orange]]
  if use-panic? [
    ask survivors [
      if is-patch? patch-at-heading-and-distance (180 + heading) vision [
        if [pcolor] of patch-ahead vision = orange or [pcolor] of patch-at-heading-and-distance (180 + heading) vision = orange [
          set panic 2
          set speed 1.8056 ; 6.5km/h = 1.8056m/s
        ]
      ]

      if is-patch? patch-at-heading-and-distance (180 + heading) (vision / 2) [
        if [pcolor] of patch-ahead (vision / 2) = orange or [pcolor] of patch-at-heading-and-distance (180 + heading) (vision / 2) = orange [
          set panic 3
          set speed 2.5 ; 9km/h = 2.5m/s
        ]
      ]

      ;    set speed base-speed * panic
    ]
  ]

  ifelse behaviour = "smart"
  [ move-normal ]
  [ follow-crowd ]

  ; Compute force exerted by survivors on each patch
  ask survivors [
    if compute-force patch-here >= health [
      ifelse color = blue
      [ set blue-stampede-deaths blue-stampede-deaths + 1]
      [ ifelse color = cyan
        [ set cyan-stampede-deaths cyan-stampede-deaths + 1 ]
        [ ifelse color = yellow
          [ set yellow-stampede-deaths yellow-stampede-deaths + 1 ]
          [ ifelse color = red
            [ set red-stampede-deaths red-stampede-deaths + 1 ]
            [ ifelse color = 29
              [ set beige-stampede-deaths beige-stampede-deaths + 1 ]
              [ set green-stampede-deaths green-stampede-deaths + 1 ]
            ]
          ]
        ]
      ]

      ifelse gender = "female"
      [ set female-stampede-deaths female-stampede-deaths + 1 ]
      [ set male-stampede-deaths male-stampede-deaths + 1 ]

      ifelse age = "child"
      [ set child-stampede-deaths child-stampede-deaths + 1 ]
      [ ifelse age = "adult"
        [ set adult-stampede-deaths adult-stampede-deaths + 1 ]
        [ set elderly-stampede-deaths elderly-stampede-deaths + 1 ]
      ]

      die
    ]
  ]

  tick
end

to-report compute-force [ p ]
  ; Force exerted by survivors in the patch
  ; acceleration = (vFinal−vInitial)/(tFinal−tInitial)
  ; Force = mass x acceleration
  let force 0
  ask survivors-on p [
    set force force + mass * speed
  ]
  report force
end

to spread-fire
  ; Fire expands every 2 seconds
  if ticks mod 10 = 0 [
    ask patches with [ pcolor = orange ] [
      ask neighbors with [ pcolor != black ] [
        set pcolor orange
      ]
    ]
  ]

  ask survivors [
    ;; Kill survivors on patches which have caught fire
    if [ pcolor ] of patch-here = orange [
      ifelse color = blue
      [ set blue-fire-deaths blue-fire-deaths + 1]
      [ ifelse color = cyan
        [ set cyan-fire-deaths cyan-fire-deaths + 1 ]
        [ ifelse color = yellow
          [ set yellow-fire-deaths yellow-fire-deaths + 1 ]
          [ ifelse color = red
            [ set red-fire-deaths red-fire-deaths + 1 ]
            [ ifelse color = 29
              [ set beige-fire-deaths beige-fire-deaths + 1 ]
              [ set green-fire-deaths green-fire-deaths + 1 ]
            ]
          ]
        ]
      ]

      ifelse gender = "female"
      [ set female-fire-deaths female-fire-deaths + 1 ]
      [ set male-fire-deaths male-fire-deaths + 1 ]

      ifelse age = "child"
      [ set child-fire-deaths child-fire-deaths + 1 ]
      [ ifelse age = "adult"
        [ set adult-fire-deaths adult-fire-deaths + 1 ]
        [ set elderly-fire-deaths elderly-fire-deaths + 1 ]
      ]
      die
    ]
  ]

  ;; kill exit door
  set oldgoal FALSE
  ask doors [
    if [ pcolor ] of patch-here = orange [set oldgoal true
      die ]
  ]
;  let shortest 0
  ask survivors [ set goal min-one-of doors [distance myself]
  ]
end

to move-normal
  ask survivors [
    let next-patch 0
    ifelse goal = door 14178 [set next-patch min-one-of neighbors [distance1]] [
      ifelse goal = door 14179 [set next-patch min-one-of neighbors [distance2]] [
        ifelse goal = door 14180 [set next-patch min-one-of neighbors [distance3]] [
          ifelse goal = door 14181 [set next-patch min-one-of neighbors [distance4]] [
            ifelse goal = door 14182 [set next-patch min-one-of neighbors [distance5]] [
              ifelse goal = door 14183 [set next-patch min-one-of neighbors [distance6]] [
                ifelse goal = door 14184 [set next-patch min-one-of neighbors [distance7]] [
                  ifelse goal = door 14185 [set next-patch min-one-of neighbors [distance8]] [
                    ifelse goal = door 14186 [set next-patch min-one-of neighbors [distance9]] [
                      ifelse goal = door 14187 [set next-patch min-one-of neighbors [distance10]] []]]]]]]]]]
    repeat speed [
      while [ [pcolor] of next-patch != grey] [
        ask next-patch [
          set distance1 10000000
          set distance2 10000000
          set distance3 10000000
          set distance4 10000000
          set distance5 10000000
          set distance6 10000000
          set distance7 10000000
          set distance8 10000000
          set distance9 10000000
          set distance10 10000000
        ]
        ifelse goal = door 14178 [set next-patch min-one-of neighbors [distance1]] [
          ifelse goal = door 14179 [set next-patch min-one-of neighbors [distance2]] [
            ifelse goal = door 14180 [set next-patch min-one-of neighbors [distance3]] [
              ifelse goal = door 14181 [set next-patch min-one-of neighbors [distance4]] [
                ifelse goal = door 14182 [set next-patch min-one-of neighbors [distance5]] [
                  ifelse goal = door 14183 [set next-patch min-one-of neighbors [distance6]] [
                    ifelse goal = door 14184 [set next-patch min-one-of neighbors [distance7]] [
                      ifelse goal = door 14185 [set next-patch min-one-of neighbors [distance8]] [
                        ifelse goal = door 14186 [set next-patch min-one-of neighbors [distance9]] [
                          ifelse goal = door 14187 [set next-patch min-one-of neighbors [distance10]] []]]]]]]]]]
      ]

      if not patch-overcrowded? next-patch [ move-to next-patch ]
    ]
    if any? doors-here [
      ifelse color = blue
      [ set blue-escapees blue-escapees + 1]
      [ ifelse color = cyan
        [ set cyan-escapees cyan-escapees + 1 ]
        [ ifelse color = yellow
          [ set yellow-escapees yellow-escapees + 1 ]
          [ ifelse color = red
            [ set red-escapees red-escapees + 1 ]
            [ ifelse color = 29
              [ set beige-escapees beige-escapees + 1 ]
              [ set green-escapees green-escapees + 1 ]
            ]
          ]
        ]
      ]

      ifelse gender = "female"
      [ set female-escapees female-escapees + 1 ]
      [ set male-escapees male-escapees + 1 ]

      ifelse age = "child"
      [ set child-escapees child-escapees + 1 ]
      [ ifelse age = "adult"
        [ set adult-escapees adult-escapees + 1 ]
        [ set elderly-escapees elderly-escapees + 1 ]
      ]

      die
    ]
  ]
end

to follow-crowd
  ;ask patches [set distancefire distance (min-one-of patches with [pcolor = orange] [distance myself]) ]
  ask survivors [

    let next-patch 0
    ifelse any? patches in-radius vision with [any? doors-here] [
          set goal min-one-of doors [distance myself]
          ifelse goal = door 14178 [set next-patch min-one-of neighbors [distance1]] [
            ifelse goal = door 14179 [set next-patch min-one-of neighbors [distance2]] [
              ifelse goal = door 14180 [set next-patch min-one-of neighbors [distance3]] [
                ifelse goal = door 14181 [set next-patch min-one-of neighbors [distance4]] [
                  ifelse goal = door 14182 [set next-patch min-one-of neighbors [distance5]] [
                    ifelse goal = door 14183 [set next-patch min-one-of neighbors [distance6]] [
                      ifelse goal = door 14184 [set next-patch min-one-of neighbors [distance7]] [
                        ifelse goal = door 14185 [set next-patch min-one-of neighbors [distance8]] [
                          ifelse goal = door 14186 [set next-patch min-one-of neighbors [distance9]] [
                            ifelse goal = door 14187 [set next-patch min-one-of neighbors [distance10]] []]]]]]]]]]


          while [ [pcolor] of next-patch != grey] [
            ask next-patch [
              set distance1 10000000
              set distance2 10000000
              set distance3 10000000
              set distance4 10000000
              set distance5 10000000
              set distance6 10000000
              set distance7 10000000
              set distance8 10000000
              set distance9 10000000
              set distance10 10000000
            ]
            ifelse goal = door 14178 [set next-patch min-one-of neighbors [distance1]] [
              ifelse goal = door 14179 [set next-patch min-one-of neighbors [distance2]] [
                ifelse goal = door 14180 [set next-patch min-one-of neighbors [distance3]] [
                  ifelse goal = door 14181 [set next-patch min-one-of neighbors [distance4]] [
                    ifelse goal = door 14182 [set next-patch min-one-of neighbors [distance5]] [
                      ifelse goal = door 14183 [set next-patch min-one-of neighbors [distance6]] [
                        ifelse goal = door 14184 [set next-patch min-one-of neighbors [distance7]] [
                          ifelse goal = door 14185 [set next-patch min-one-of neighbors [distance8]] [
                            ifelse goal = door 14186 [set next-patch min-one-of neighbors [distance9]] [
                              ifelse goal = door 14187 [set next-patch min-one-of neighbors [distance10]] []]]]]]]]]]

          ]
      ][
      ifelse is-patch? patch-at-heading-and-distance (180 + heading) vision and is-patch? patch-at-heading-and-distance (90 + heading) vision and is-patch? patch-at-heading-and-distance (270 + heading) vision [
        ifelse [pcolor] of patch-ahead vision = orange or [pcolor] of patch-at-heading-and-distance (180 + heading) vision = orange or [pcolor] of patch-at-heading-and-distance (90 + heading) vision = orange or [pcolor] of patch-at-heading-and-distance (270 + heading) vision = orange [
          set next-patch max-one-of neighbors [distancefire]
          while [ [pcolor] of next-patch != grey] [
            ask next-patch [set distancefire 0]
            set next-patch max-one-of neighbors [distancefire]
          ]
          if not patch-overcrowded? next-patch [ move-to next-patch ]
        ][
          if any? turtles-on neighbors [
            let avg mean [heading] of turtles-on neighbors
            ifelse avg <= 90 [set heading 90][
              ifelse avg <= 180 [set heading 180][
                ifelse avg <= 270 [set heading 270][
                  set heading 0
                ]
              ]
            ]

            if [pcolor] of patch-ahead 1 = gray [fd 1]
          ]
        ]

      ][]


    ]


]


end

to setup-stadium
  draw-rectangle -163 135 321 105 gray
  create-blue1
  create-blue2
  create-blue3
  create-cyan1
  create-cyan2
  create-cyan3
  create-yellow1
  create-yellow2
  create-yellow3
  create-yellow4
  create-yellow5
  create-lime1
  create-lime2
  create-lime3
  create-green1
  create-green2
  create-green3
  draw-rectangle -250 25 500 8 gray
  draw-rectangle -14 17 25 18 white ;draw center bridge
  ;draw-black
  draw-leftbridge
  draw-rightbridge
  draw-rectangle -114 3 228 80 gray  ;draw floating platform
  create-stairs1 ;create all left-facing stairs
  create-stairs2 ;create all right-facing stairs
end

to set-survivors-attributes
  ask survivors [
    ; Set gender
    ifelse random-float 1.0 < 0.4805
    [ set gender "male" ]
    [ set gender "female" ]

    ; Set age
    ifelse random-float 1.0 <= 0.1498
    [ set age "child" ]
    [ ifelse random-float 1.0 < 0.8708
      [ set age "adult" ]
      [ set age "elderly" ]
    ]
;    set age random-normal 42.4 20

    ; Set base speed
    ifelse age = "child"
    [ set base-speed 0.3889 ] ; 1.4km/h = 0.38889m/s
    [ ifelse age = "adult"
      [ set base-speed random-float-between 1.4778 1.5083 ] ; 5.32km/h = 1.4778m/s and 5.43km/h = 1.5083m/s
      [ set base-speed random-float-between 1.2528 1.3194 ] ; 4.51km/h = 1.2528m/s and 4.75km/h = 1.3194m/s
    ]
    set speed base-speed
;    ifelse age < 15
;    [ set speed 1.4 ]
;    [ ifelse age < 65
;      [ set speed random-float-between 5.32 5.43 ]
;      [ set speed random-float-between 4.51 4.75 ]
;    ]

    ; Set mass
    ifelse age = "child"
    [ ifelse gender = "male"
      [ set mass random-normal 40 4]
      [ set mass random-normal 35 4]
    ]
    [ set mass random-normal 57.7 4 ]
    ; Set health
    set health mass * speed * threshold
;    show health

    ; Set vision
    set vision random max-vision

    ; Set panic level
    set panic 1
  ]
end

to-report random-float-between [ #min #max ]  ; random float in given range
  report #min + random-float (#max - #min)
end

to-report patch-overcrowded? [ p ]
  report count turtles-on p > 10
end


to create-stairs1
  let xlist create-xlist4 82
  let ylist create-ylist2 5 30
  (foreach xlist ylist [ [x y] ->
    draw-rectangle x y 2 1 gray
    ])
  set xlist create-xlist4 44
  set ylist create-ylist2 5 30
  (foreach xlist ylist [ [x y] ->
    draw-rectangle x y 2 1 gray
    ])
  set xlist create-xlist4 -33
  set ylist create-ylist2 5 30
  (foreach xlist ylist [ [x y] ->
    draw-rectangle x y 2 1 gray
    ])
  set xlist create-xlist4 -70
  set ylist create-ylist2 5 30
  (foreach xlist ylist [ [x y] ->
    draw-rectangle x y 2 1 gray
    ])
  set xlist create-xlist4 -127
  set ylist create-ylist2 5 30
  (foreach xlist ylist [ [x y] ->
    draw-rectangle x y 2 1 gray
    ])
end

to create-stairs2
  let xlist create-xlist5 121
  let ylist create-ylist2 5 30
  (foreach xlist ylist [ [x y] ->
    draw-rectangle x y 2 1 gray
    ])
  set xlist create-xlist5 64
  set ylist create-ylist2 5 30
  (foreach xlist ylist [ [x y] ->
    draw-rectangle x y 2 1 gray
    ])
  set xlist create-xlist5 26
  set ylist create-ylist2 5 30
  (foreach xlist ylist [ [x y] ->
    draw-rectangle x y 2 1 gray
    ])
  set xlist create-xlist5 -50
  set ylist create-ylist2 5 30
  (foreach xlist ylist [ [x y] ->
    draw-rectangle x y 2 1 gray
    ])
  set xlist create-xlist5 -88
  set ylist create-ylist2 5 30
  (foreach xlist ylist [ [x y] ->
    draw-rectangle x y 2 1 gray
    ])
end

to create-blue1
  let ylist create-ylist 17 135
  let peoplelist create-peoplelist 17 -163
  (foreach ylist [ [y] ->
    draw-rectangle -163 y 17 1 blue
   (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color blue set heading 180]])
    ])
  set ylist create-ylist 17 100
  (foreach ylist [ [y] ->
    draw-rectangle -163 y 17 1 blue
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color blue set heading 180]])
    ])
  let xlist create-xlist -163
  set ylist create-ylist 17 65
  let wlist create-wlist 17
  (foreach xlist ylist wlist [ [x y w] ->
    draw-rectangle x y w 1 blue
    set peoplelist create-peoplelist w x
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color blue set heading 180]])
    ])
end
to create-blue2
  let ylist create-ylist 17 135
  let peoplelist create-peoplelist 17 -144
  (foreach ylist [ [y] ->
    draw-rectangle -144 y 17 1 blue
    ;(foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color blue set heading 180]])
    ])
  set ylist create-ylist 17 100
  (foreach ylist [ [y] ->
    draw-rectangle -144 y 17 1 blue
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color blue set heading 180]])
    ])
  set ylist create-ylist 17 65
  (foreach ylist [ [y] ->
    draw-rectangle -144 y 17 1 blue
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color blue set heading 180]])
    ])
end
to create-blue3
  let ylist create-ylist 17 135
  let peoplelist create-peoplelist 17 -125
  (foreach ylist [ [y] ->
    draw-rectangle -125 y 17 1 blue
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color blue set heading 180]])
    ])
  set ylist create-ylist 17 100
  (foreach ylist [ [y] ->
    draw-rectangle -125 y 17 1 blue
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color blue set heading 180]])
    ])
  set ylist create-ylist 17 65
  (foreach ylist [ [y] ->
    draw-rectangle -125 y 17 1 blue
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color blue set heading 180]])
    ])
end

to create-cyan1
  let ylist create-ylist 17 135
  let peoplelist create-peoplelist 17 -106
  (foreach ylist [ [y] ->
    draw-rectangle -106 y 17 1 cyan
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color cyan set heading 180]])
    ])
  set ylist create-ylist 17 100
  (foreach ylist [ [y] ->
    draw-rectangle -106 y 17 1 cyan
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color cyan set heading 180]])
    ])
  set ylist create-ylist 17 65
  (foreach ylist [ [y] ->
    draw-rectangle -106 y 17 1 cyan
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color cyan set heading 180]])
    ])
end
to create-cyan2
  let ylist create-ylist 17 135
  let peoplelist create-peoplelist 17 -87
  (foreach ylist [ [y] ->
    draw-rectangle -87 y 17 1 cyan
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color cyan set heading 180]])
    ])
  set ylist create-ylist 17 100
  (foreach ylist [ [y] ->
    draw-rectangle -87 y 17 1 cyan
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color cyan set heading 180]])
    ])
  set ylist create-ylist 17 65
  (foreach ylist [ [y] ->
    draw-rectangle -87 y 17 1 cyan
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color cyan set heading 180]])
    ])
end
to create-cyan3
  let ylist create-ylist 17 135
  let peoplelist create-peoplelist 17 -68
  (foreach ylist [ [y] ->
    draw-rectangle -68 y 17 1 cyan
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color cyan set heading 180]])
    ])
  set ylist create-ylist 17 100
  (foreach ylist [ [y] ->
    draw-rectangle -68 y 17 1 cyan
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color cyan set heading 180]])
    ])
  set ylist create-ylist 17 65
  (foreach ylist [ [y] ->
    draw-rectangle -68 y 17 1 cyan
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color cyan set heading 180]])
    ])
end

to create-yellow1
  let ylist create-ylist 17 135
  let peoplelist create-peoplelist 17 -49
  (foreach ylist [ [y] ->
    draw-rectangle -49 y 17 1 yellow
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color yellow set heading 180]])
    ])
  set ylist create-ylist 17 100
  (foreach ylist [ [y] ->
    draw-rectangle -49 y 17 1 yellow
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color yellow set heading 180]])
    ])
  set ylist create-ylist 17 65
  (foreach ylist [ [y] ->
    draw-rectangle -49 y 17 1 yellow
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color yellow set heading 180]])
    ])
end
to create-yellow2
  let ylist create-ylist 17 135
  let peoplelist create-peoplelist 17 -30
  (foreach ylist [ [y] ->
    draw-rectangle -30 y 17 1 yellow
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color yellow set heading 180]])
    ])
  set ylist create-ylist 17 100
  (foreach ylist [ [y] ->
    draw-rectangle -30 y 17 1 red
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color red set heading 180]])
    ])
  set ylist create-ylist 17 65
  (foreach ylist [ [y] ->
    draw-rectangle -30 y 17 1 red
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color red set heading 180]])
    ])
end
to create-yellow3
  let ylist create-ylist 17 135
  let peoplelist create-peoplelist 17 -11
  (foreach ylist [ [y] ->
    draw-rectangle -11 y 17 1 yellow
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color yellow set heading 180]])
    ])
  set ylist create-ylist 17 100
  (foreach ylist [ [y] ->
    draw-rectangle -11 y 17 1 red
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color red set heading 180]])
    ])
  set ylist create-ylist 17 65
  (foreach ylist [ [y] ->
    draw-rectangle -11 y 17 1 red
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color red set heading 180]])
    ])
end
to create-yellow4
  let ylist create-ylist 17 135
  let peoplelist create-peoplelist 17 8
  (foreach ylist [ [y] ->
    draw-rectangle 8 y 17 1 yellow
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color yellow set heading 180]])
    ])
  set ylist create-ylist 17 100
  (foreach ylist [ [y] ->
    draw-rectangle 8 y 17 1 red
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color red set heading 180]])
    ])
  set ylist create-ylist 17 65
  (foreach ylist [ [y] ->
    draw-rectangle 8 y 17 1 red
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color red set heading 180]])
    ])
end
to create-yellow5
  let ylist create-ylist 17 135
  let peoplelist create-peoplelist 17 27
  (foreach ylist [ [y] ->
    draw-rectangle 27 y 17 1 yellow
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color yellow set heading 180]])
    ])
  set ylist create-ylist 17 100
  (foreach ylist [ [y] ->
    draw-rectangle 27 y 17 1 yellow
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color yellow set heading 180]])
    ])
  set ylist create-ylist 17 65
  (foreach ylist [ [y] ->
    draw-rectangle 27 y 17 1 yellow
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color yellow set heading 180]])
    ])
end

to create-lime1
  let ylist create-ylist 17 135
  let peoplelist create-peoplelist 17 46
  (foreach ylist [ [y] ->
    draw-rectangle 46 y 17 1 29
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color 29 set heading 180]])
    ])
  set ylist create-ylist 17 100
  (foreach ylist [ [y] ->
    draw-rectangle 46 y 17 1 29
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color 29 set heading 180]])
    ])
  set ylist create-ylist 17 65
  (foreach ylist [ [y] ->
    draw-rectangle 46 y 17 1 29
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color 29 set heading 180]])
    ])
end
to create-lime2
  let ylist create-ylist 17 135
  let peoplelist create-peoplelist 17 65
  (foreach ylist [ [y] ->
    draw-rectangle 65 y 17 1 29
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color 29 set heading 180]])
    ])
  set ylist create-ylist 17 100
  (foreach ylist [ [y] ->
    draw-rectangle 65 y 17 1 29
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color 29 set heading 180]])
    ])
  set ylist create-ylist 17 65
  (foreach ylist [ [y] ->
    draw-rectangle 65 y 17 1 29
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color 29 set heading 180]])
    ])
end
to create-lime3
  let ylist create-ylist 17 135
  let peoplelist create-peoplelist 17 84
  (foreach ylist [ [y] ->
    draw-rectangle 84 y 17 1 29
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color 29 set heading 180]])
    ])
  set ylist create-ylist 17 100
  (foreach ylist [ [y] ->
    draw-rectangle 84 y 17 1 29
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color 29 set heading 180]])
    ])
  set ylist create-ylist 17 65
  (foreach ylist [ [y] ->
    draw-rectangle 84 y 17 1 29
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color 29 set heading 180]])
    ])
end

to create-green1
  let ylist create-ylist 17 135
  let peoplelist create-peoplelist 17 103
  (foreach ylist [ [y] ->
    draw-rectangle 103 y 17 1 green
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color green set heading 180]])
    ])
  set ylist create-ylist 17 100
  (foreach ylist [ [y] ->
    draw-rectangle 103 y 17 1 green
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color green set heading 180]])
    ])
  set ylist create-ylist 17 65
  (foreach ylist [ [y] ->
    draw-rectangle 103 y 17 1 green
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color green set heading 180]])
    ])
end
to create-green2
  let ylist create-ylist 17 135
  let peoplelist create-peoplelist 17 122
  (foreach ylist [ [y] ->
    draw-rectangle 122 y 17 1 green
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color green set heading 180]])
    ])
  set ylist create-ylist 17 100
  (foreach ylist [ [y] ->
    draw-rectangle 122 y 17 1 green
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color green set heading 180]])
    ])
  set ylist create-ylist 17 65
  (foreach ylist [ [y] ->
    draw-rectangle 122 y 17 1 green
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color green set heading 180]])
    ])
end
to create-green3
  let ylist create-ylist 17 135
  let peoplelist create-peoplelist 17 141
  (foreach ylist [ [y] ->
    draw-rectangle 141 y 17 1 green
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color green set heading 180]])
    ])
  set ylist create-ylist 17 100
  (foreach ylist [ [y] ->
    draw-rectangle 141 y 17 1 green
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color green set heading 180]])
    ])
  set ylist create-ylist 17 65
  let wlist create-wlist 17
  (foreach ylist wlist [ [y w] ->
    draw-rectangle 141 y w 1 green
    set peoplelist create-peoplelist w 141
    (foreach peoplelist [ [ppl] -> create-survivors 1 [setxy ppl y set color green set heading 180]])
    ])
end

to-report create-xlist5 [input]
  report n-values (5) [ [i] -> input - i * 1]
end

to-report create-xlist4 [input]
  report n-values (5) [ [i] -> input + i * 1]
end

to-report create-xlist3 [input]
  report n-values (14) [ [i] -> input - i * 1]
end

to-report create-xlist2 [input]
  report n-values (14) [ [i] -> input + i * 1]
end

to-report create-ylist2 [input1 input2]
  report n-values (input1) [ [i] -> input2 - i * 1]
end

to-report create-xlist [input]
  report n-values (17) [ [i] -> input + i * 1]
end

to-report create-ylist [input1 input2]
  report n-values (input1) [ [i] -> input2 - i * 2]
end

to-report create-wlist [input]
  report n-values (17) [ [i] -> input - i * 1]
end

to-report create-peoplelist [input1 input2]
  report n-values (input1) [ [i] -> input2 + i]
end

to draw-rectangle [ x y w l c ]
  ask patches with
  [ w + x > pxcor and pxcor >= x
    and
    y >= pycor and pycor > (y - l) ] [ set pcolor c ]
end

to draw-leftbridge
  let xlist create-xlist2 -120
  let ylist create-ylist2 14 17
  (foreach xlist ylist [ [x y] ->
    draw-rectangle x y 17 1 white
    ])
end

to draw-rightbridge
  let xlist create-xlist3 94
  let ylist create-ylist2 14 17
  (foreach xlist ylist [ [x y] ->
    draw-rectangle x y 17 1 white
    ])
end
@#$#@#$#@
GRAPHICS-WINDOW
261
10
1581
1062
-1
-1
3.85
1
10
1
1
1
0
0
0
1
-170
170
-135
135
1
1
1
ticks
1.0

BUTTON
4
450
70
483
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
75
450
138
483
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
4
139
116
184
No. of survivors
count survivors
17
1
11

CHOOSER
3
46
141
91
behaviour
behaviour
"smart" "follow"
0

MONITOR
3
189
104
234
Total Escapees
blue-escapees + cyan-escapees + yellow-escapees + red-escapees + beige-escapees + green-escapees
17
1
11

SLIDER
4
99
176
132
threshold
threshold
10
100
60.0
10
1
NIL
HORIZONTAL

PLOT
4
295
261
445
Survivors
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Survivors" 1.0 0 -16777216 true "" "plot count survivors"
"Escapees" 1.0 0 -13840069 true "" "plot blue-escapees + cyan-escapees + yellow-escapees + red-escapees + beige-escapees + green-escapees"
"Stampede" 1.0 0 -2674135 true "" "plot blue-stampede-deaths + cyan-stampede-deaths + yellow-stampede-deaths + red-stampede-deaths + beige-stampede-deaths + green-stampede-deaths"
"Fire-deaths" 1.0 0 -955883 true "" "plot blue-fire-deaths + cyan-fire-deaths + yellow-fire-deaths + red-fire-deaths + beige-fire-deaths + green-fire-deaths"

MONITOR
4
243
78
288
Fire victims
blue-fire-deaths + cyan-fire-deaths + yellow-fire-deaths + red-fire-deaths + beige-fire-deaths + green-fire-deaths
17
1
11

MONITOR
85
243
195
288
Stampede victims
blue-stampede-deaths + cyan-stampede-deaths + yellow-stampede-deaths + red-stampede-deaths + beige-stampede-deaths + green-stampede-deaths
17
1
11

BUTTON
4
487
165
520
go until no survivors
go\nif count survivors = 0 [ stop ]
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
111
189
213
234
Available Exits
count doors
17
1
11

PLOT
6
733
251
883
Escapees by Color
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"blue" 1.0 0 -13345367 true "" "plot blue-escapees"
"cyan" 1.0 0 -11221820 true "" "plot cyan-escapees"
"yellow" 1.0 0 -1184463 true "" "plot yellow-escapees"
"red" 1.0 0 -2674135 true "" "plot red-escapees"
"beige" 1.0 0 -204336 true "" "plot beige-escapees"
"green" 1.0 0 -10899396 true "" "plot green-escapees"

PLOT
6
891
248
1041
Stampede victims by Color
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"blue" 1.0 0 -13345367 true "" "plot blue-stampede-deaths"
"cyan" 1.0 0 -11221820 true "" "plot cyan-stampede-deaths"
"yellow" 1.0 0 -1184463 true "" "plot yellow-stampede-deaths"
"red" 1.0 0 -2674135 true "" "plot red-stampede-deaths"
"beige" 1.0 0 -204336 true "" "plot beige-stampede-deaths"
"green" 1.0 0 -10899396 true "" "plot green-stampede-deaths"

PLOT
5
1049
248
1199
Fire victims by Color
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"blue" 1.0 0 -13345367 true "" "plot blue-fire-deaths"
"cyan" 1.0 0 -11221820 true "" "plot cyan-fire-deaths"
"red" 1.0 0 -2674135 true "" "plot red-fire-deaths"
"yellow" 1.0 0 -1184463 true "" "plot yellow-fire-deaths"
"beige" 1.0 0 -204336 true "" "plot beige-fire-deaths"
"green" 1.0 0 -10899396 true "" "plot green-fire-deaths"

SLIDER
3
10
175
43
max-vision
max-vision
20
100
50.0
5
1
NIL
HORIZONTAL

MONITOR
3
524
118
569
Average panic level
precision mean [panic] of survivors 5
17
1
11

MONITOR
122
524
258
569
Top speed (m/s)
precision mean [speed] of survivors 3
17
1
11

SWITCH
147
50
259
83
use-panic?
use-panic?
0
1
-1000

SWITCH
124
144
249
177
random-fire?
random-fire?
1
1
-1000

PLOT
6
576
250
726
Average panic level
NIL
NIL
0.0
10.0
1.0
3.0
true
true
"" ""
PENS
"blue" 1.0 0 -13345367 true "" "plot mean [ panic ] of survivors with [ color = blue ]"
"cyan" 1.0 0 -11221820 true "" "plot mean [ panic ] of survivors with [ color = cyan ]"
"yellow" 1.0 0 -1184463 true "" "plot mean [ panic ] of survivors with [ color = yellow ]"
"red" 1.0 0 -2674135 true "" "plot mean [ panic ] of survivors with [ color = red ]"
"beige" 1.0 0 -204336 true "" "plot mean [ panic ] of survivors with [ color = 29 ]"
"green" 1.0 0 -10899396 true "" "plot mean [ panic ] of survivors with [ color = green ]"

BUTTON
143
452
208
487
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
1590
12
1852
162
Escapees by Gender
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"female" 1.0 0 -2674135 true "" "plot female-escapees"
"male" 1.0 0 -13345367 true "" "plot male-escapees"

PLOT
1590
475
1855
625
Escapees by Age Group
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"child" 1.0 0 -2064490 true "" "plot child-escapees"
"adult" 1.0 0 -5825686 true "" "plot adult-escapees"
"senior" 1.0 0 -8630108 true "" "plot elderly-escapees"

PLOT
1590
166
1852
316
Fire Deaths by Gender
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"female" 1.0 0 -2674135 true "" "plot female-fire-deaths"
"male" 1.0 0 -13345367 true "" "plot male-fire-deaths"

PLOT
1590
319
1855
469
Stampede Deaths by Gender
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"female" 1.0 0 -2674135 true "" "plot female-stampede-deaths"
"male" 1.0 0 -13345367 true "" "plot male-stampede-deaths"

PLOT
1592
628
1852
778
Fire Deaths by Age Group
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"child" 1.0 0 -2064490 true "" "plot child-fire-deaths"
"adult" 1.0 0 -5825686 true "" "plot adult-fire-deaths"
"senior" 1.0 0 -8630108 true "" "plot elderly-fire-deaths"

PLOT
1593
783
1869
933
Stampede Deaths by Age Group
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"child" 1.0 0 -2064490 true "" "plot child-stampede-deaths"
"adult" 1.0 0 -5825686 true "" "plot adult-stampede-deaths"
"senior" 1.0 0 -8630108 true "" "plot elderly-stampede-deaths"

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
