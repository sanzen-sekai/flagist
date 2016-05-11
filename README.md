# flagist

flag addon to active model

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'flagist'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install flagist

## Usage

初期化  
ActiveModel::Model に flagist クラスメソッドをインクルードする

気になるなら、各モデルで `include Flagist` でも良い

```ruby
# config/initializers/flagist.rb
Flagist.install
# ActiveModel::Model.send :include, Flagist
```

フラグ設定は各モデルで行う

```ruby
# app/models/my_model.rb
class MyModel < ActiveRecord::Base
  flagist do |flag|
    flag.is_active true, false

    flag.color nil => :blank, 1 => :yellow, 2 => :red, 3 => :green

    flag.roles :admin, :user, :guest

    # flag.フラグ ( 値, 値, 値, ... )
    # flag.フラグ ( 値 => name, ... )

    # フラグ名を複数形で指定すると type: :array になる
    # その場合の型は String で、値のカンマ区切りで保存される

    # name が String で指定された場合、 symbol に変換される
  end
end
```

i18n

```yml
# config/locales/models/my_model/ja.yml
ja:
  activerecord:
    flags:
      my_model:
        is_active:
          true:  有効
          false: 無効
        color:
          blank: なし
          yellow: 黄
          red:    赤
          green:  緑
        roles:
          admin: 管理
          user:  ユーザー
          guest: ゲスト
```

ラベル情報の取得

```ruby
MyModel.is_active_labels #=> {true => "有効", false => "無効"}
MyModel.is_active_names  #=> {true => true,   false => false}

MyModel.color_labels #=> {nil => "なし", 1 => "黄",    2 => "赤", 3 => "緑"}
MyModel.color_names  #=> {nil => :blank, 1 => :yellow, 2 => :red, 3 => :green}

MyModel.roles_labels #=> {:admin => "管理", :user => "ユーザー", :guest => "ゲスト"}
MyModel.roles_names  #=> {:admin => :admin, :user => :user,      :guest => :guest}


MyModel.color_labels_inverse #=> {"なし" => nil, "黄"    => 1, "赤" => 2, "緑"   => 3}
MyModel.color_names_inverse  #=> {:blank => nil, :yellow => 1, :red => 2, :green => 3}
```

値の取得

値、 name, label のどれを指定しても良い  
それぞれに重複するものがあるとおかしくなるが、そもそもそんな設定はおかしい

```ruby
MyModel.is_active(true)   #=> true
MyModel.is_active("有効") #=> true

MyModel.is_active_name(true)   #=> true
MyModel.is_active_name("有効") #=> true

MyModel.is_active_label(true)   #=> "有効"
MyModel.is_active_label("有効") #=> "有効"


MyModel.color(1)       #=> 1
MyModel.color(:yellow) #=> 1
MyModel.color("黄")    #=> 1

MyModel.color_name(1)       #=> :yellow
MyModel.color_name(:yellow) #=> :yellow
MyModel.color_name("黄")    #=> :yellow

MyModel.color_label(1)       #=> "黄"
MyModel.color_label(:yellow) #=> "黄"
MyModel.color_label("黄")    #=> "黄"


MyModel.roles(:admin)       #=> :admin
MyModel.roles("管理")       #=> :admin

MyModel.roles_name(:admin)  #=> :admin
MyModel.roles_name("管理")  #=> :admin

MyModel.roles_label(:admin) #=> "管理"
MyModel.roles_label("管理") #=> "管理"
```

配列で指定すると配列で戻る

```ruby
MyModel.roles_label([:admin, :user]) #=> ["管理", "ユーザー"]
```

存在しない場合は例外が発生

```ruby
MyModel.roles_label("マネージャー") #=> raise Flagist::UnknownFlagError
```

インスタンスメソッド  
`type: :array` の場合、 `roles_name`, `roles_label` の戻り値は配列になる

戻り値は freeze して返される

```ruby
model = MyModel.new

model.is_active       #=> true
model.is_active_name  #=> true
model.is_active_label #=> "有効"

model.color       #=> 1
model.color_name  #=> :yellow
model.color_label #=> "黄"

model.roles       #=> "admin,user"
model.roles_name  #=> [:admin,:user]
model.roles_label #=> ["管理","ユーザー"]
```

クラスメソッドと同様の呼び出しも可能

```ruby
model = MyModel.new

model.is_active(true)   #=> true
model.is_active("有効") #=> true

model.is_active_name(true)   #=> true
model.is_active_name("有効") #=> true

model.is_active_label(true)   #=> "有効"
model.is_active_label("有効") #=> "有効"


model.color(1)       #=> 1
model.color(:yellow) #=> 1
model.color("黄")    #=> 1

model.color_name(1)       #=> :yellow
model.color_name(:yellow) #=> :yellow
model.color_name("黄")    #=> :yellow

model.color_label(1)       #=> "黄"
model.color_label(:yellow) #=> "黄"
model.color_label("黄")    #=> "黄"


model.roles(:admin)       #=> :admin
model.roles("管理")       #=> :admin

model.roles_name(:admin)  #=> "管理"
model.roles_name("管理")  #=> "管理"

model.roles_label(:admin) #=> "管理"
model.roles_label("管理") #=> "管理"


model.roles_label([:admin, :user]) #=> ["管理", "ユーザー"]
```

値の設定

```ruby
model = MyModel.new

model.is_active = true
model.is_active_name = true
model.is_active_label = "有効"

model.color = 1
model.color_name = :yellow
model.color_label = "黄"

model.roles = "admin,user"
model.roles_name = [:admin,:user]
model.roles_label = ["管理","ユーザー"]
```

存在しない場合は例外が発生

```ruby
model.roles_label = ["マネージャー"] #=> raise Flagist::UnknownFlagError
```

第一引数にオプションを渡すと :type の上書きが可能

```ruby
flag.is_active {type: :scalar}, true, false
```

全設定の dump

```ruby
MyModel.flagist
# => {
#   is_active: {
#     type: :scalar,
#     flags: {
#       true  => {value: true,  name: true,  label: "有効"},
#       false => {value: false, name: false, label: "無効"},
#     },
#   },
#   color: {
#     type: :scalar,
#     flags: {
#       nil => {value: nil, name: :blank,  label: "なし"},
#       1   => {value: 1,   name: :yellow, label: "黄"},
#       2   => {value: 2,   name: :red,    label: "赤"},
#       3   => {value: 3,   name: :green,  label: "緑"},
#     },
#   },
#   roles: {
#     type: :array,
#     flags: {
#       :admin => {value: :admin, name: :admin, label: "管理"},
#       :user  => {value: :user,  name: :user,  label: "ユーザー"},
#       :guest => {value: :guest, name: :guest, label: "ゲスト"},
#     },
#   },
# }
# # i18n が設定されていない場合は label には name が使用される
# # この時、 name が明示的に指定されていない場合は label は nil が使用される
```

## Configure

設定可能なパラメータとデフォルト

```ruby
# config/initializers/flagist.rb
Flagist.configure do |config|
  config.i18n_namespace = "activerecord.flags" # I18n.translate でカラム名を取得する際の namespace
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sanzen-sekai/flagist.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

