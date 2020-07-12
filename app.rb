require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'
require 'pony'

post '/contacts' do
  @usernameForm = params[:usernameForm]
  @userphoneForm = params[:userphoneForm]

  Pony.mail({
    :to => 'stasnedosekin59@gmail.com',
    :subject => "Обратная связь со страницы Контакты",
    :body => "Имя: #{@usernameForm}""\n\r""Телефон: #{@userphoneForm}",
    :via => :smtp,
    :via_options => {
      :address              => 'smtp.gmail.com',
      :port                 => '587',
      :enable_starttls_auto => true,
      :user_name            => 'stasnedosekin59@gmail.com',
      :password             => 'rrvlsghzyazyfnet',
      :authentication       => :plain, # :plain, :login, :cram_md5, no auth by default
      :domain               => "localhost.localdomain" # the HELO domain provided by the client to the server
    }
  })
  erb "<h2>Спасибо, мы вам перезвоним</h2> <a href="/">На главную</a>"
end

# Экземпляр объекта нужно обязательно вернуть так как в configure код будет выполнен 1 раз при инициализации (Когда изменили код)
def get_db
  db = SQLite3::Database.new 'barberschop.db'
  db.results_as_hash = true
  return db
end

before do
  db = get_db
  @barbers = db.execute 'select * from Barbers'
end

def is_barber_exists? db, name
  db.execute('select * from Barbers where name=?', [name]).length > 0 
end

def seed_db db, barbers
  barbers.each do |item|
    if !is_barber_exists? db, item
      db.execute 'insert into Barbers (name) values (?)', [item]
    end
  end
end

configure do
  enable :sessions

  db = get_db
  db.execute 'CREATE TABLE IF NOT EXISTS 
              "Users"(
              "id" INTEGER PRIMARY KEY AUTOINCREMENT, 
              "username" TEXT, 
              "phone" TEXT, 
              "datestamp" TEXT, 
              "barber" TEXT, 
              "color" TEXT)'

  db.execute 'CREATE TABLE IF NOT EXISTS 
              "Barbers"(
              "id" INTEGER PRIMARY KEY AUTOINCREMENT, 
              "name" TEXT)'

  seed_db db, ['Валя Дурдомова', 'Олеська Куралеська', 'Петровна Кудряхова', 'Валя Челканова']

end

get '/' do
  erb 'Добро пожаловать на наш сайт'
end

get '/about' do
  erb :about
end

get '/visit' do
  erb :visit
end

post '/visit' do

  @username = params[:username]
  @phone = params[:phone]
  @datetime = params[:datetime]
  @barber = params[:barber]
  @color = params[:color]

  hh = {
    :username => 'Введите имя', 
    :phone => 'Введите телефон', 
    :datetime => 'Введите дату и время'
  }

  # Вывод ошибки по каждому input при submit
  
  # hh.each do |key, value|
  #   if params[key] == ''
  #     @error = hh[key]
  #     return  erb :visit
  #   end
  # end

  @error = hh.select {|key,_| params[key] == ""}.values.join(", ")

  if @error != ''
    return erb :visit
  end

  db = get_db
  db.execute 'insert into
              Users(
                username,
                phone,
                datestamp,
                barber,
                color)
              values(?,?,?,?,?)', [@username, @phone, @datetime, @barber, @color]

  erb "<h2>Спасибо, мы ждем вас!</h2>"
end

get '/contacts' do
  erb :contacts
end

get '/showusers' do
  db = get_db
  @results = db.execute 'select * from Users order by id desc'
  erb :showusers
end
