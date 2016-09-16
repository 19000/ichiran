(in-package :ichiran/dict)

;; SPLITS (words that should be scored as two or more other words)

(defparameter *split-map* (make-hash-table)) ;; seq -> split function

(defmacro defsplit (name seq (reading-var) &body body)
  `(progn
     (defun ,name (,reading-var) ;; reading -> (values parts score-bonus)
       ,@body)
     (setf (gethash ,seq *split-map*) ',name)))

(defmacro def-simple-split (name seq score (&optional length-var text-var reading-var) &body parts-def)
  "each part is (seq length-form)"
  (alexandria:with-gensyms (offset parts pseq part-length)
    (unless reading-var (setf reading-var (gensym "RV")))
    (unless length-var (setf length-var (gensym "LV")))
    (unless text-var (setf text-var (gensym "TV")))
    `(defsplit ,name ,seq (,reading-var)
       (let* ((,text-var (true-text ,reading-var))
              (,length-var (length ,text-var))
              (,offset 0)
              (,parts nil))
         (declare (ignorable ,text-var ,length-var))
         ,@(loop for (part-seq part-length-form conj-p rendaku-p) in parts-def
              if (eql part-seq :test)
                collect
                `(unless ,part-length-form
                   (return-from ,name nil))
              else
              collect
                `(let ((,pseq ,(if (listp part-seq)
                                   (if (and part-seq (stringp (car part-seq)))
                                       `(list (seq (car (find-word-conj-of ,@part-seq))))
                                       `',part-seq)
                                   `',(list part-seq)))
                       (,part-length ,part-length-form))
                   (push (car (apply
                               ,(if conj-p
                                   ''find-word-conj-of
                                   ''find-word-seq)
                                (let ((part-txt (subseq ,text-var ,offset 
                                                       (and ,part-length (+ ,offset ,part-length)))))
                                  ,(if rendaku-p
                                      '(unrendaku part-txt)
                                      'part-txt))
                                ,pseq))
                         ,parts)
                   (when ,part-length
                     (incf ,offset ,part-length))))
         (values (nreverse ,parts) ,score)))))

(defun get-split* (reading &optional conj-of)
  (let ((split-fn (gethash (seq reading) *split-map*)))
    (if split-fn
        (funcall split-fn reading)
        (loop for seq in conj-of
           for split-fn = (gethash seq *split-map*)
           when split-fn do (return (funcall split-fn reading))))))

(defun get-split (reading &optional conj-of)
  "Includes safety check if one of split words is missing"
  (multiple-value-bind (split score) (get-split* reading conj-of)
    (when (and split (every 'identity split))
      (values split score))))

;; split definitions

;; -de expressions (need to be split otherwise -desune parses as -de sune)

(defmacro def-de-split (seq seq-a &key (score 15))
  (let ((name (intern (format nil "~a~a" :split-de- seq))))
    `(def-simple-split ,name ,seq ,score (len)
       (,seq-a (- len 1))
       (2028980 1))))

(def-de-split 1163700 1576150) ;; 一人で

(def-de-split 1611020 1577100) ;; 何で

(def-de-split 1004800 1628530) ;; これで

(def-de-split 1413430 1413420) ;; 大急ぎで

(def-de-split 2810720 1004820) ;; 此れまでで

(def-de-split 1006840 1006880) ;; その上で

(def-de-split 1530610 1530600) ;; 無断で

(def-de-split 1245390 1245290) ;; 空で

(def-de-split 2719270 1445430) ;; 土足で

(def-de-split 1189420 2416780) ;; 何用で

(def-de-split 1221800 1591410) ;; 気まぐれで

(def-de-split 1263640 1630950) ;; 現行犯で

(def-de-split 1272220 1592990) ;; 交代で

(def-de-split 1311360 1311350) ;; 私費で

(def-de-split 1317210 1611820) ;; 耳元で

(def-de-split 1368500 1368490) ;; 人前で

(def-de-split 1395670 1395660) ;; 全体で

(def-de-split 1417790 1417780) ;; 単独で

(def-de-split 1454270 1454260) ;; 道理で

(def-de-split 1479100 1679020) ;; 半眼で

(def-de-split 1510140 1680900) ;; 別封で

(def-de-split 1510170 1510160) ;; 別便で

(def-de-split 1518550 1529560) ;; 無しで

(def-de-split 1528270 1528260) ;; 密室で

(def-de-split 1531420 1531410) ;; 名義で

(def-de-split 1597400 1585205) ;; 力尽くで

(def-de-split 1679990 2582460) ;; 抜き足で

(def-de-split 1682060 2085340) ;; 金ずくで

(def-de-split 1736650 1611710) ;; 水入らずで

(def-de-split 1865020 1590150) ;; 陰で

(def-de-split 1878880 2423450) ;; 差しで

(def-de-split 2126220 1802920) ;; 捩じり鉢巻きで

(def-de-split 2136520 2005870) ;; もう少しで

(def-de-split 2276140 1188520) ;; 何やかやで

(def-de-split 2513590 2513650) ;; 詰め開きで

(def-de-split 2771850 2563780) ;; 気にしないで

(def-de-split 2810800 1587590) ;; 今までで

(def-de-split 1343110 1343100) ;; ところで


(defmacro def-toori-split (seq seq-a &key (score 50) (seq-b 1432930))
  (let ((name (intern (format nil "~a~a" :split-toori- seq))))
    `(def-simple-split ,name ,seq ,score (len txt r)
       (:test (eql (word-type r) :kanji))
       (,seq-a (- len 2))
       (,seq-b 2))))

(def-toori-split 1260990 1260670) ;; 元通り

(def-toori-split 1414570 2082450) ;; 大通り

(def-toori-split 1424950 1620400) ;; 中通り [ちゅう通り]
(def-toori-split 1424960 1423310) ;; 中通り [なか通り]

(def-toori-split 1820790 1250090) ;; 型通り

(def-toori-split 1489800 1489340) ;; 表通り

(def-toori-split 1523010 1522150) ;; 本通り

(def-toori-split 1808080 1604890) ;; 目通り

(def-toori-split 1368820 1580640) ;; 人通り

(def-toori-split 1550490 1550190) ;; 裏通り

(def-toori-split 1619440 2069220) ;; 素通り

(def-toori-split 1164910 2821500 :seq-b 1432920) ;; 一通り

(def-toori-split 1462720 1461140 :seq-b 1432920) ;; 二通り

;; nakunaru split: because naku often attaches to previous word

(def-simple-split split-nakunaru 1529550 30 (len) ;; 無くなる
  (("無く" 1529520) 2)
  (1375610 nil t))

(def-simple-split split-nakunaru2 1518540 10 (len txt r) ;; 亡くなる
  (:test (eql (word-type r) :kana))
  (("亡く" 1518450) 2)
  (1375610 nil t))

;; tegakakaru split (kana form might conflict with other uses of kakaru verb)

(def-simple-split split-tegakakaru 2089710 10 (len) ;; 手が掛かる
  (1327190 1) ;; 手
  (2028930 1) ;; が
  (1207590 nil t))
  

(def-simple-split split-kawaribae 1411570 10 (len txt) ;; 代わり映え
  ((1590770 1510720) (1+ (position #\り txt)))
  (1600610 2 nil t))

(def-simple-split split-hayaimonode 2815260 100 (len txt) ;; 早いもので
  (1404975 (1+ (position #\い txt)))
  (1502390 (if (find #\物 txt) 1 2))
  (2028980 1))

(def-simple-split split-dogatsukeru 2800540 30 (len) ;; ドが付ける
  (2252690 1)
  (2028930 1)
  (1495740 nil t))

(def-simple-split split-janaika 2819990 20 (len) ;; じゃないか
  (("じゃない" 2089020) 4)
  (2028970 1))

(def-simple-split split-kaasan 1609470 50 (len txt r) ;; 母さん
  (:test (eql (word-type r) :kanji))
  (1514990 1)
  (1005340 2))

(def-simple-split split-souda 1006650 5 (len)
  (2137720 2)
  ((2089020 1628500)))

(def-simple-split split-kinosei 1221750 100 (len txt r)
  (1221520 1)
  (1469800 1)
  (1610040 2))

(def-simple-split split-nanimokamo 1599590 20 (len) ;; なにもかも
  (1188490 (- len 2))
  (2143350 2))

(def-simple-split split-katawonaraberu 2102910 20 (len txt) ;; 肩を並べる
  (1258950 (position #\を txt))
  (2029010 1)
  (1508390 nil t))

(def-simple-split split-moushiwakenasasou 2057340 300 (len txt) ;; 申し訳なさそう
  (1363050 (position #\な txt))
  (2246510))

;; KANA HINTS (indicate when to romanize は as わ etc.)

(defparameter *kana-hint-mod* #\u200c)
(defparameter *kana-hint-space* #\u200b)

(defparameter *hint-char-map* `(:space ,*kana-hint-space* :mod ,*kana-hint-mod*))

(defparameter *hint-simplify-map*
  (list (string *kana-hint-space*) " "
        (coerce (list *kana-hint-mod* #\は) 'string) "わ"
        (coerce (list *kana-hint-mod* #\ハ) 'string) "ワ"
        (coerce (list *kana-hint-mod* #\へ) 'string) "え"
        (coerce (list *kana-hint-mod* #\ヘ) 'string) "エ"
        (string *kana-hint-mod*) ""))

(defun process-hints (word)
  (simplify-ngrams word *hint-simplify-map*))

(defparameter *kana-hint-map* (make-hash-table)) ;; seq -> split function

(defun insert-hints (str hints &aux (len (length str)))
  ;; hints are ((character-kw position) ...)
  (unless hints
    (return-from insert-hints str))
  (let ((positions (make-array (1+ len) :initial-element nil)))
    (loop for (character-kw position) in hints
       for char = (getf *hint-char-map* character-kw)
       when (<= 0 position len)
       do (push char (aref positions position)))
    (with-output-to-string (s)
      (loop for i from 0 upto len
         do (loop for char in (reverse (aref positions i))
               do (write-char char s))
         when (< i len)
         do (write-char (char str i) s)))))

(defparameter *hint-map* (make-hash-table)) ;; seq -> hint function

(defmacro defhint (seqs (reading-var) &body body)
  (unless (listp seqs)
    (setf seqs (list seqs)))
  (alexandria:with-gensyms (fn)
    `(let ((,fn (lambda (,reading-var) ,@body)))
       ,@(loop for seq in seqs
            collect `(setf (gethash ,seq *hint-map*) ,fn)))))

(defmacro def-simple-hint (seqs (&optional length-var kana-var reading-var) &body hints-def
                           &aux test-var test-var-used)
  (unless reading-var (setf reading-var (gensym "RV")))
  (unless length-var (setf length-var (gensym "LV")))
  (unless kana-var (setf kana-var (gensym "KV")))
  (setf test-var (gensym "TV"))
  `(defhint ,seqs (,reading-var)
     (block hint
       (let* ((,kana-var (true-kana ,reading-var))
              (,length-var (length ,kana-var))
              ,@(loop for (var value) in hints-def
                     for tvar = (cond ((eql var :test) (setf test-var-used t) test-var)
                                      ((keywordp var) nil)
                                      (t var))
                     when tvar collect `(,tvar (or ,value (return-from hint nil)))))
         (declare (ignorable ,length-var ,@(when test-var-used (list test-var))))
         (insert-hints (get-kana ,reading-var)
                       (list
                        ,@(loop for pair in hints-def
                             when (and (keywordp (car pair)) (not (eql (car pair) :test)))
                             collect `(list ,@pair))))))))

(defun get-hint (reading)
  (let ((hint-fn (gethash (seq reading) *hint-map*))
        (conj-of (mapcar #'conj-data-from (word-conj-data reading))))
    (if hint-fn
        (funcall hint-fn reading)
        (loop for seq in conj-of
           for hint-fn = (gethash seq *hint-map*)
           when hint-fn do (return (funcall hint-fn reading))))))

;; expressions ending with は

#|
(query (:select 'kt.seq 'kt.text :from (:as 'kana-text 'kt) (:as 'sense-prop 'sp)
                              :where (:and (:= 'kt.seq 'sp.seq)
                                           (:= 'sp.tag "pos")
                                           (:= 'sp.text "exp")
                                           (:like 'kt.text "%は"))))
|#

;; TODO pos=int, pos=adv

(def-simple-hint ;; no space
    (1289480 ;; こんばんは
     1289400 ;; こんにちは
     1004620 ;; こにちは
     1008450 ;; では
     2215430 ;; には
     2028950 ;; とは
     )
    (l k)
  (:test (alexandria:ends-with #\は k))
  (:mod (- l 1)))

(def-simple-hint ;; with space
    (1006660 ;; そうでないばあいは
     1008500 ;; というのは
     1307530 ;; はじめは
     1320830 ;; じつは
     1324320 ;; もしくは
     1524990 ;; または
     1586850 ;; あるいは
     1586850 ;; あるは
     1877880 ;; ごきぼうのむきは
     1897510 ;; ところでは
     1907300 ;; へいそは
     1912570 ;; もとは
     2034440 ;; にかけては
     2036130 ;; うはうは
     2098160 ;; なくては
     2105820 ;; にしては
     2134680 ;; それは
     2136300 ;; ということは
     2173060 ;; それいがいのものは
     2176280 ;; これは
     2177410 ;; のぞむらくは
     2177420 ;; おそらくは
     2177430 ;; おしむらくは
     2177440 ;; うらむらくは
     2177450 ;; こいねがわくは
     2256430 ;; としては
     2428890 ;; さすがは
     2513540 ;; そのことじたいは
     2523450 ;; おかれましては
     2557290 ;; なんだこれは
     2629620 ;; だけは
     2673120 ;; かくなるうえは
     2691570 ;; あいなるべくは
     2702090 ;; ては
     2717440 ;; ずは
     2717510 ;; ってのは
     2828541 ;; あさのは
     2176280 ;; これは
     1316430 ;; つぎのれいでは
     1217970 ;; 希わくは
     1260080 ;; 見方によっては
     1263700 ;; 現時点においては
     1331520 ;; 就きましては
     1907290 ;; 平生は
     1914670 ;; 要は
     1950430 ;; 果ては
     2136680 ;; 無くしては
     2181810 ;; 上は
     2181730 ;; 然上は
     1217970 ;; 願わくは
     2181730 ;; 然る上は
     2576840 ;; 何時かは
     2181730 ;; しかる上は
     1331510 ;; 就いては
     1010470 ;; 延いては
     2008290 ;; さては
     2136690 ;; にあっては
     )
    (l k)
  (:test (alexandria:ends-with #\は k))
  (:space (- l 1))
  (:mod (- l 1)))

(def-simple-hint
    (2261800 ;; それはそれは
     )
    (l)
  (:space 2)
  (:mod 2)
  (:space 3)
  (:space (- l 1))
  (:mod (- l 1)))

(def-simple-hint ;; では/には ending
    (1009480 ;; ならでは
     1315860 ;; ときには
     1406050 ;; それでは
     1550170 ;; りろんてきには
     1917520 ;; わたくしなどには
     1917530 ;; わたくしのほうでは
     2026610 ;; からには
     2061740 ;; みたかぎりでは
     2097310 ;; ただでは
     2101020 ;; あるいみでは
     2119920 ;; そのわりには
     2134700 ;; なしには
     2200100 ;; うえでは
     2407650 ;; このぶんでは
     2553140 ;; こんにちでは
     2762790 ;; ひとつには
     1288910 ;; いまでは
     1423320 ;; なかにわ
     2099850 ;; ないことには
     1006890 ;; そのばあいには
     1887540 ;; 成功の暁には
     )
    (l k)
  (:test (alexandria:ends-with #\は k))
  (:space (- l 2))
  (:mod (- l 1)))

;; では expressions

(def-simple-hint
    (2089020 ;; だ
     2823770 ;; ではない
     2098240 ;; ではある
     2027020 ;; ではないか
     2135480 ;; ではまた
     2397760 ;; ではありますまいか
     2724540 ;; ではなかろうか
     2757720 ;; ではなさそう
     )
    (l k)
  (deha (search "では" k :from-end t))
  (:mod (1+ deha)))

(def-simple-hint ;; ends with ではない
    (1922645 ;; ふつうではない
     2027080 ;; べきではない
     2118000 ;; ひとごとではない
     2126160 ;; どうじつのだんではない
     2126140 ;; でるまくではない
     2131120 ;; たいしたことではない
     2136640 ;; といってもかごんではない
     2214830 ;; すてたものではない
     2221680 ;; いわないことではない
     2416950 ;; ばかりがのうではない
     2419210 ;; どうじつのろんではない
     2664520 ;; たまったものではない
     2682500 ;; しょうきのさたではない
     2775790 ;; それどころではない
     1343120 ;; どころではない
     1012260 ;; まんざらゆめではない
     2112270 ;; もののかずではない
     2404260 ;; しったことではない
     2523700 ;; ほんいではない
     2758400 ;; みられたものではない
     2827556 ;; だけがのうではない
     2057560 ;; わけではない
     2088970 ;; しないのではないか
     2088970 ;; ないのではないか
     )
    (l k)
  (deha (search "では" k :from-end t))
  (:space deha)
  (:mod (1+ deha)))

;; では in the middle
(def-simple-hint
    (2037860 ;; ただではおかないぞ
     2694350 ;; ころんでもただではおきない
     2111220 ;; ひとすじなわではいかない
     2694360 ;; ころんでもただではおきぬ
     2182700 ;; ないではいられない
     )
    (l k)
  (deha (search "では" k :from-end t))
  (:space deha)
  (:mod (1+ deha))
  (:space (+ 2 deha)))

;; には in the middle
(def-simple-hint
    (2057580 ;; わけにはいかない
     2067990 ;; つうにはたまらない
     2103020 ;; かわいいこにはたびをさせよ
     2105980 ;; てきをあざむくにはまずみかたから
     2152700 ;; わらうかどにはふくきたる
     2416920 ;; なくことじとうにはかてぬ
     2418030 ;; うえにはうえがある
     2792210 ;; れいにはおよばない
     2792420 ;; おれいにはおよびません
     2417920 ;; おんなのかみのけにはたいぞうもつながる
     2598720 ;; せきぜんのいえにはかならずよけいあり
     2420170 ;; きれいなばらにはとげがある
     2597190 ;; わけにはいけない
     2597800 ;; せきふぜんのいえにはかならずよおうあり
     2057570 ;; わけにはいきません
     2419360 ;; ねんにはねんをいれよ
     2121480 ;; うらにはうらがある
     2646440 ;; のこりものにはふくがある
     2740880 ;; なくことじとうにはかてない
     2416860 ;; よるとしなみにはかてない
     2156910 ;; ひとのくちにはとがたてられない
     )
    (l k)
  (niha (search "には" k :from-end t))
  (:space niha)
  (:mod (1+ niha))
  (:space (+ 2 niha)))

;; starts with には/とは

(def-simple-hint
    (2181860 ;; にはおよばない
     2037320 ;; とはいえ
     2125460 ;; とはべつに
     2128060 ;; とはいうものの
     2070730 ;; とはかぎらない
     )
    (l k)
  (:mod 1)
  (:space 2))

;; は in the middle
(def-simple-hint
    (2101500 ;; 無い袖は振れぬ
     2142010 ;; 口では大阪の城も建つ
     2118440 ;; なにはなくとも
     2118430 ;; なにはともあれ
     2152710 ;; わたるせけんにおにはない
     2216540 ;; せにはらはかえられぬ
     2757560 ;; よいごしのぜにはもたない
     2424500 ;; もくてきのためにはしゅだんをえらばない
     2078950 ;; せにはらはかえられない
     2118120 ;; なにはさておき
     2108910 ;; かたいことはいいっこなし
     2403520 ;; どうということはない
     2411180 ;; ようじんするにこしたことはない
     2419710 ;; きくとみるとはおおちがい
     2585230 ;; ことはない
     1008970 ;; どうってことはない
     2418060 ;; いろごとはしあんのほか
     2418490 ;; せけんのくちにとはたてられぬ
     2761670 ;; さきのことはわからない
     2419270 ;; にどあることはさんどある
     2600530 ;; それとはなしに
     2670900 ;; おせじにもうまいとはいえない
     2135530 ;; ほどのことはない
     2136710 ;; ということはない
     2708230 ;; なんのことはない
     1188440 ;; なんとはなしに
     2741810 ;; いいあとはわるい
     2195810 ;; にこしたことはない
     2418280 ;; ひとはなさけ
     2419410 ;; ばかとはさみはつかいよう
     2416580 ;; わるいことはできぬもの
     2417180 ;; みるときくとはおおちがい
     2418220 ;; ひとのくちにとはたてられず
     2826812 ;; わるいことはいわない
     2420010 ;; ようじんにこしたことはない
     2792090 ;; しょうきとはおもえない
     1949380 ;; むりはない
     2209690 ;; おとこににごんはない
     2210960 ;; かちめはない
     2418900 ;; ただよりたかいものはない
     2420110 ;; れいがいのないきそくはない
     2419420 ;; ばかにつけるくすりはない
     2419970 ;; よのじしょにふかのうというもじはない
     2641030 ;; あいてにとってふそくはない
     2744840 ;; ざまはない
     2747300 ;; タダめしはない
     2418900 ;; タダよりたかいものはない
     2747300 ;; ただめしはない
     2798610 ;; おみきあがらぬかみはない
     1638390 ;; ようじんするにしくはない
     2089750 ;; なにかいいてはないか
     2442180 ;; いのちにべつじょうはない
     )
    (l k)
  (ha (search "は" k :from-end t))
  (:space ha)
  (:mod ha)
  (:space (1+ ha)))

(def-simple-hint
    (2108440 ;; あやまちてはすなわちあらたむるにはばかることなかれ
     2784400 ;; かにはこうらににせてあなをほる
     2418270 ;; ひとはみかけによらぬもの
     2219580 ;; ねごとはねてからいえ
     2418250 ;; ひとはパンのみにていくるものにあらず
     2417270 ;; あとはのとなれやまとなれ
     2178680 ;; だすことはしたをだすもきらい
     )
    (l k)
  (ha (search "は" k :from-end t))
  (:space ha)
  (:mod ha)
  (:space (1+ ha)))

;; ha twice in the middle
(def-simple-hint
    (2416600 ;; 悪人は畳の上では死ねない
     2767400 ;; おにはそとふくはうち
     2418260 ;; ひとはいちだいなはまつだい
     2828341 ;; はなはさくらぎひとはぶし
     )
    (l k)
  (ha1 (search "は" k))
  (ha2 (search "は" k :from-end t))
  (:space ha1)
  (:mod ha1)
  (:space (1+ ha1))
  (:space ha2)
  (:mod ha2)
  (:space (1+ ha2)))

(def-simple-hint
    (2153170 ;; めにはめをはにははを
     )
    (l k)
  (niha1 (search "には" k))
  (niha2 (search "には" k :from-end t))
  (wo1 (search "を" k))
  (wo2 (search "を" k :from-end t))
  (:space niha1)
  (:mod (1+ niha1))
  (:space (+ 2 niha1))
  (:space niha2)
  (:mod (1+ niha2))
  (:space (+ 2 niha2))
  (:space wo1)
  (:space (1+ wo1))
  (:space wo2))

(def-simple-hint
    (2422970 ;; 人には添うて見よ馬には乗って見よ
     )
    (l k)
  (niha1 (search "には" k))
  (niha2 (search "には" k :from-end t))
  (yo1 (search "よ" k))
  (:space niha1)
  (:mod (1+ niha1))
  (:space (+ 2 niha1))
  (:space niha2)
  (:mod (1+ niha2))
  (:space (+ 2 niha2))
  (:space (1+ yo1)))


