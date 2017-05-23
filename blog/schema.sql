drop table if exists blogs;

create table blogs (
	id integer primary key autoincrement,
	title string not null,
	text string not null
);
