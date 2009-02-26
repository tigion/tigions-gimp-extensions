; TODO:
; - Bildgroesse auf Vorgabe reduzieren
; - Anwendung auf Größe des aktuellen Layers oder auf gesamtes Bild

; define function
(define 
  (script-fu-blog-image-inside-shadow
    img
    drawable
    shadow_size
    shadow_color
    shadow_strength
  )

  (let*
    (
      (save_color_foreground (car (gimp-context-get-foreground)))
      (save_color_background (car (gimp-context-get-background)))
      (img_width (car (gimp-image-width img)))
      (img_height (car (gimp-image-height img)))

      ;(use_... FALSE)

      (new_img_width)
      (new_img_height)
      (xpos 0)
      (ypos 0)

      (newlayer_shadow)
      (newlayer_shadow2)

      (color_black '(0 0 0))
      (color_white '(255 255 255))
    )

    ; ---------------------------------------------------------------
    ; create useful variables
    ; ---------------------------------------------------------------

    ; calc new size
    (set! new_img_width  (+ img_width  (* 2 shadow_size)))
    (set! new_img_height (+ img_height (* 2 shadow_size)))
    (set! xpos shadow_size)
    (set! ypos shadow_size)

    ; ---------------------------------------------------------------
    ; start point for undo group
    ; ---------------------------------------------------------------

    (gimp-undo-push-group-start img)

    ; ---------------------------------------------------------------
    ; clear and save gimp state
    ; ---------------------------------------------------------------

    ; set active layer
    (gimp-image-set-active-layer img drawable)

    ; clear possible selections
    (gimp-selection-none img)

    ; convert gray/indexed images to rgb color
    (if (= (car (gimp-drawable-is-rgb drawable)) FALSE)
      (gimp-image-convert-rgb img)
      ;(gimp-message "TODO: Hinweis ...")
    )

    ; ---------------------------------------------------------------
    ; prepare the image
    ; ---------------------------------------------------------------
 
    ; ---------------------------------------------------------------
    ; do the amazing stuff now
    ; ---------------------------------------------------------------

    ; select all
    (gimp-selection-all img)

    ; resize image (shadow + 2x shadow size)
    (gimp-image-resize img new_img_width new_img_height xpos ypos)

    ; create new transparent layer for shadowmask
    (set! newlayer_shadow
      (car
        (gimp-layer-new
          img
          (car (gimp-image-width img))
          (car (gimp-image-height img))
          RGBA-IMAGE
          "temp"
          100
          NORMAL
        )
      )
    )
    (gimp-image-add-layer img newlayer_shadow -1)
    (gimp-drawable-fill newlayer_shadow TRANSPARENT-FILL)

    ; invert selection
    (gimp-selection-invert img)

    ; set foreground color to color1
    (gimp-context-set-foreground color_white)
    ; fill selection 1 with color1
    (gimp-edit-fill newlayer_shadow FOREGROUND-FILL)

    ; remove selection
    (gimp-selection-none img)

    ; create shadow and merge result layers (> 100% 2x)
    (if (> shadow_strength 100)
      (begin
        ; create shadows
        (script-fu-drop-shadow img newlayer_shadow 0 0 shadow_size shadow_color 100 FALSE)
        (script-fu-drop-shadow img newlayer_shadow 0 0 shadow_size shadow_color (- shadow_strength 100) FALSE)
        ; merge layers
        (set! newlayer_shadow (car (gimp-image-merge-down img newlayer_shadow EXPAND-AS-NECESSARY)))
        (set! newlayer_shadow (car (gimp-image-merge-down img newlayer_shadow EXPAND-AS-NECESSARY)))
      )
      (begin
        ; create shadow
        (script-fu-drop-shadow img newlayer_shadow 0 0 shadow_size shadow_color shadow_strength FALSE)
        ; merge layer
        (set! newlayer_shadow (car (gimp-image-merge-down img newlayer_shadow EXPAND-AS-NECESSARY)))
      )
    )
    ; set layer name
    (gimp-drawable-set-name newlayer_shadow "Shadow (inside)")

    ; resize image to selection
    (gimp-image-resize img img_width img_height (- 0 xpos) (- 0 ypos))
    ; resize shadow layer to image size
    (gimp-layer-resize-to-image-size newlayer_shadow)

    ; ---------------------------------------------------------------
    ; reset gimp state
    ; ---------------------------------------------------------------

    ; clear forgotten selections
    (gimp-selection-none img)

    ; restore colors
    (gimp-context-set-foreground save_color_foreground)
    (gimp-context-set-background save_color_background)

    ; ---------------------------------------------------------------
    ; end point for undo group
    ; ---------------------------------------------------------------

    (gimp-undo-push-group-end img)
    
    ; ---------------------------------------------------------------
    ; finish
    ; ---------------------------------------------------------------

    ; display result
    (gimp-displays-flush img)

    ; return values
    (list newlayer_shadow)
  )
)

; register function
(script-fu-register
  "script-fu-blog-image-inside-shadow" ; function name
  "Blogbild (inside shadow) ..." ; menu label
  "Creates an inside shadow around the image." ; description
  "Christoph Zirkelbach" ; author
  "Christoph Zirkelbach" ; copyright notice
  "February 24, 2009" ; date created
  "" ; image type that the script works on
  SF-IMAGE       "Image" 0
  SF-DRAWABLE    "Drawable" 0
  SF-ADJUSTMENT  "Schattengröße" '(15 1 1024 1 10 0 1)
  SF-COLOR       "Schattenfarbe" '(0 0 0)
  SF-ADJUSTMENT  "Schattenstärke" '(150 0 200 1 10 0 1)
)
(script-fu-menu-register "script-fu-blog-image-inside-shadow" "<Image>/Script-Fu/Blog/")
