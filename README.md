# flask-blog
首先来看一下我们的目录结构：
```
/blog
    /static
    /templates
```
blog下面存放的是我们数据库文件以及项目的主文件目录，static存放的是网页编写需要的css和JavaScript文件，而templates存放的就是我们编写的jinja2模板。简单的介绍到这了，下面我们开始编写代码吧

###### 创建数据库
首先在根目录下创建schema.sql文件
```
drop table if exists blogs;
create table blogs (
    id integer primary key autoincrement,
    title string not null,
    text string not null
);
```
然后在根目录下创建blog.py文件，该文件作为整个项目的主文件，包含项目的相关配置
```
# 导入所有的模块
import sqlite3
from flask import Flask, request, session, g, redirect, url_for, abort, render_template, flash

# 配置文件
DATABASE = '/tmp/blog.db'
DEBUG = True
SECRET_KEY = 'development key'
USERNAME = 'admin'
PASSWORD = 'admin'

# 创建应用
app = Flask(__name__)
# from_object会搜寻定义里的全部大写的变量，即上面的各项设置
app.config.from_object(__name__)
#from_envvar设置BLOG_SETTINGS变量来设定是否从配置文件载入文件后覆盖默认值，
#silent设置为True后就表明不关心该值
app.config.from_envvar('BLOG_SETTINGS', silent=True)

def connect_db():
    return sqlite3.connect(app.config['DATABASE'])

if __name__ == '__main__':
    app.run()
```
上面的代码只是对该项目进行了简单的设置，下面通过init_db来进行数据库的操作请求
```
def init_db():
	with closing(connect_db()) as db:
		with app.open_resource('schema.sql') as f:
			db.cursor().executescript(f.read())
		db.commit()
```
不仅如此，sqlite3还允许我们在数据库操作前后进行操作:
```
@app.before_request
def before_request():
	g.db = connect_db()

@app.teardown_request
def teardown_request(exception):
	g.db.close()
```
这样在我们init_db的之前连接数据库，读取数据完成之后进行数据库的关闭

下面我们编写四个界面
```
@app.route('/')
def show_blogs():
	cur = g.db.execute('select title, text from blogs order by id desc')
	blogs = [dict(title=row[0],text=row[1])for row in cur.fetchall()]
	return render_template('show_blogs.html',blogs = blogs)

@app.route('/add',methods=['POST'])
def add_blog():
	if not session.get('logged_in'):
		abort(401)
	g.db.execute('insert into blogs (title,text) values(?,?)',[request.form['title'],request.form['text']])
	g.db.commit()
	flash('New entry was successfully posted')
	return redirect(url_for('show_blogs'))

@app.route('/login',methods=['GET','POST'])
def login():
	error = None
	if request.method == 'POST':
		if request.form['username']!=app.config['USERNAME']:
			error = 'Invalid username';
		elif request.form['password']!=app.config['PASSWORD']:
			error = 'Invalid password'
		else:
			session['logged_in']=True
			flash('You were logged in')
			return redirect(url_for('show_blogs'))
	return render_template('login.html',error=error)
@app.route('/logout')
def logout():
	session.pop('logged_in',None)
	flash('You were logged out')
	return redirect(url_for('show_blogs'))
```
在show_blogs的时候，我们从数据库获取到我们的blogs,然后使用template文件夹下面保存的show_blog.html，并将blogs传递过去，方便页面进行数据的展示。

然后在add_blog中首先判断用户是否登录，如果登录之后，就进行数据库的插入操作，最后将页面重定向到show_blogs所代表的url上。

登录login看起来比较复杂，其实就是用户的判断，这里直接用简单的模拟一下登录，如果登录成功就重定向到show_blogs上去，如果失败，就跳转到login界面去

最后logout其实就是将我们在session中存储的用户登录信息给清除掉，并重定向到show_blogs，这里面的逻辑行为交由页面进行处理。

对于页面编写的话，这里也没什么好说的，我这里就不再赘述了。
