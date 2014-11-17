(in-package :ichiran/test)

(defmacro assert-segment (str &rest segmentation)
  `(assert-equal ',segmentation
                 (mapcar (lambda (wi) (if (eql (word-info-type wi) :gap) :gap
                                          (word-info-text wi)))
                         (simple-segment ,str))
                 ))

(define-test segmentation-test
  (assert-segment "ご注文はうさぎですか" "ご注文" "は" "うさぎ" "です" "か")
  (assert-segment "しませんか" "しません" "か")
  (assert-segment "ドンマイ" "ドンマイ")
  (assert-segment "みんな土足でおいで" "みんな" "土足で" "おいで")
  (assert-segment "おもわぬオチ提供中" "おもわぬ" "オチ" "提供" "中")
  (assert-segment "わたし" "わたし")
  (assert-segment "お姉ちゃんにまかせて地球まるごと"
                  "お姉ちゃん" "に" "まかせて" "地球" "まるごと")
  (assert-segment "大人になってるはず"
                  "大人" "に" "なってる" "はず")
  (assert-segment "いいとこ" "いいとこ")
  (assert-segment "そういうお隣どうし"
                  "そういう" "お" "隣" "どうし")
  (assert-segment "はしゃいじゃう" "はしゃいじゃう")
  (assert-segment "分かっちゃうのよ" "分かっちゃう" "の" "よ")
  (assert-segment "懐かしく新しいまだそしてまた"
                  "懐かしく" "新しい" "まだ" "そして" "また")
  (assert-segment "あたりまえみたいに思い出いっぱい"
                  "あたりまえ" "みたい" "に" "思い出" "いっぱい")
  (assert-segment "何でもない日々とっておきのメモリアル"
                  "何でもない" "日々" "とっておき" "の" "メモリアル")
  (assert-segment "しつれいしなければならないんです"
                  "しつれいし" "なければならない" "ん" "です")
  (assert-segment "だけど気付けば馴染んじゃってる"
                  "だけど" "気付けば" "馴染んじゃってる")
  (assert-segment "飲んで笑っちゃえば"
                  "飲んで" "笑っちゃえば")
  (assert-segment "なんで" "なんで")
  (assert-segment "遠慮しないでね" "遠慮しないで" "ね")
  (assert-segment "出かけるまえに" "出かける" "まえ" "に")
  (assert-segment "感じたいでしょ" "感じたい" "でしょ")
  (assert-segment "まじで" "まじ" "で")
  (assert-segment "その山を越えたとき" "その" "山" "を" "越えた" "とき")
  (assert-segment "遊びたいのに" "遊びたい" "のに")
  (assert-segment "しながき" "しながき")
  (assert-segment "楽しさ求めて" "楽しさ" "求めて")
  (assert-segment "日常のなかにも" "日常" "の" "なか" "に" "も")
  (assert-segment "ほんとは好きなんだと" "ほんと" "は" "好き" "な" "ん" "だと")
  (assert-segment "内緒なの" "内緒" "なの")
  (assert-segment "魚が好きじゃない" "魚" "が" "好き" "じゃない")
  (assert-segment "物語になってく" "物語" "に" "なってく")
  (assert-segment "書いてきてくださった" "書いてきて" "くださった")
  (assert-segment "今日は何の日" "今日" "は" "何の" "日")
  (assert-segment "何から話そうか" "何から" "話そう" "か")
  (assert-segment "話したくなる" "話したく" "なる")
  (assert-segment "進化してく友情" "進化してく" "友情")
  (assert-segment "私に任せてくれ" "私" "に" "任せてくれ")
  (assert-segment "時までに帰ってくると約束してくれるのなら外出してよろしい"
                  "時" "まで" "に" "帰ってくる" "と"
                  "約束してくれる" "の" "なら" "外出して" "よろしい")
  (assert-segment "雨が降りそうな気がします" "雨" "が" "降り" "そう" "な" "気がします")
  (assert-segment "新しそうだ" "新しそう" "だ")
  (assert-segment "本を読んだりテレビを見たりします"
                  "本" "を" "読んだり" "テレビ" "を" "見たり" "します")
  (assert-segment "今日母はたぶんうちにいるでしょう"
                  "今日" "母" "は" "たぶん" "うち" "に" "いる" "でしょう")
  (assert-segment "赤かったろうです" "赤かったろう" "です")
  (assert-segment "そう呼んでくれていい" "そう" "呼んでくれていい")
  (assert-segment "払わなくてもいい" "払わなくてもいい")
  (assert-segment "体に悪いと知りながらタバコをやめることはできない"
                  "体" "に" "悪い" "と" "知り" "ながら" "タバコ" "を" "やめる" "こと" "は" "できない")
  (assert-segment "いつもどうり" "いつも" "どうり")
  (assert-segment "微笑みはまぶしすぎる" "微笑み" "は" "まぶしすぎる")
  (assert-segment "なにをしていますか" "なに" "を" "しています" "か")
  (assert-segment "優しすぎそのうえカッコいいの" "優しすぎ" "そのうえ" "カッコいい" "の")
  (assert-segment "この本は複雑すぎるから" "この" "本" "は" "複雑" "すぎる" "から")
  (assert-segment "かわいいです" "かわいいです")
  (assert-segment "学生なんだ" "学生" "な" "ん" "だ")
  (assert-segment "なんだから" "な" "ん" "だから")
  (assert-segment "名付けたい" "名付けたい")
  (assert-segment "切なくなってしまう" "切なく" "なって" "しまう")
  (assert-segment "らいかな" "らい" "かな")
  (assert-segment "誰かいなくなった" "誰か" "いなくなった")
  (assert-segment "思い出すな" "思い出す" "な")
  (assert-segment "かなって思ったら" "かなって" "思ったら")
  (assert-segment "ことすら難しい" "こと" "すら" "難しい")
  (assert-segment "投下しました" "投下しました")
  (assert-segment "車止める" "車" "止める")
  (assert-segment "円盤はただの" "円盤" "は" "ただ" "の")
  (assert-segment "なんですね" "な" "ん" "です" "ね")
  (assert-segment "ズボンからすねをむき出しにする"
                  "ズボン" "から" "すね" "を" "むき" "出しにする")
  (assert-segment "駅の前で会いましょう"
                  "駅" "の" "前" "で" "会いましょう")
  (assert-segment "あなたの質問は答えにくい"
                  "あなた" "の" "質問" "は" "答えにくい")
  (assert-segment "とかそういう" "とか" "そういう")
  (assert-segment "好評のうちに" "好評" "の" "うち" "に")
  (assert-segment "映像もすごくよかったです" "映像" "も" "すごく" "よかったです")
  (assert-segment "情けねえ" "情けねえ")
  (assert-segment "春ですねえ" "春" "です" "ねえ")
  (assert-segment "春ですねぇ" "春" "です" "ねぇ")
  (assert-segment "きつねじゃなかった" "きつね" "じゃなかった")
  (assert-segment "ワシじゃなくて和紙じゃよ" "ワシ" "じゃなくて" "和紙" "じゃ" "よ")
  (assert-segment "ほうがいいよ" "ほうがいい" "よ")
  (assert-segment "痛さはどれくらいですか" "痛さ" "は" "どれ" "くらいです" "か")
  (assert-segment "見てくれたかな" "見てくれた" "かな")
  (assert-segment "とても良かった" "とても" "良かった")
  (assert-segment "戻りたいかと言われる" "戻りたい" "か" "と" "言われる") ;;should be と言われる at some point
  (assert-segment "こういうのでいいんだよ" "こういう" "の" "でいい" "ん" "だ" "よ")
  (assert-segment "そんなのでいいと思ってるの" "そんな" "の" "でいい" "と" "思ってる" "の")
  (assert-segment "だけが墓参りしてた" "だけ" "が" "墓参りしてた")
  (assert-segment "はいいんだけどな" "は" "いい" "ん" "だけど" "な")
  (assert-segment "なりつつあるんだが" "なりつつある" "ん" "だが")
  (assert-segment "反論は認めません" "反論" "は" "認めません")
  )

(define-test json-consistency-test
  (loop for word in '("の" "赤かったろう" "書いてきてる")
       for word-info = (car (simple-segment word))
       for word-info-json = (word-info-json word-info)
       do (assert-equal (word-info-gloss-json word-info) (word-info-gloss-json word-info-json))))

(defun run-all-tests ()
  (init-suffixes t)
  (let ((res (run-tests :all :ichiran/test)))
    (print-failures res)
    (print-errors res)
    res))
