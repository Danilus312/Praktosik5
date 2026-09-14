const http = require('http');
const url = require('url');

const PORT = 8080;

let ttlSeconds = 900;
const ttlIndex = process.argv.indexOf('--ttl');
if (ttlIndex !== -1 && process.argv[ttlIndex + 1]) {
  ttlSeconds = parseInt(process.argv[ttlIndex + 1], 10) || 900;
}

let users = [
  { id: 1, username: 'admin', password: 'password123', fullName: 'Системный администратор', role: 'admin' },
  { id: 2, username: 'librarian', password: 'password123', fullName: 'Иванова Мария Сергеевна', role: 'librarian' },
  { id: 3, username: 'reader', password: 'password123', fullName: 'Петров Алексей Викторович', role: 'reader' }
];

let refreshTokensDb = new Set();

let books = [
  { id: 1, title: 'Война и мир', isbn: '978-5-389-06256-6', year: 1869, pages: 1225, genreIds: [1, 5], publisherId: 1, authorIds: [1], isDeleted: false },
  { id: 2, title: '1984', isbn: '978-5-17-080115-2', year: 1949, pages: 320, genreIds: [2, 3], publisherId: 2, authorIds: [2], isDeleted: false },
  { id: 3, title: 'Мастер и Маргарита', isbn: '978-5-389-01686-6', year: 1967, pages: 512, genreIds: [1, 4], publisherId: 1, authorIds: [3], isDeleted: false },
  { id: 4, title: 'Преступление и наказание', isbn: '978-5-389-07446-0', year: 1866, pages: 672, genreIds: [1, 6], publisherId: 1, authorIds: [4], isDeleted: false },
  { id: 5, title: '451 градус по Фаренгейту', isbn: '978-5-17-077750-1', year: 1953, pages: 256, genreIds: [2, 3], publisherId: 2, authorIds: [5], isDeleted: false }
];

let publishers = [
  { id: 1, name: 'Азбука-Аттикус', city: 'Санкт-Петербург' },
  { id: 2, name: 'АСТ', city: 'Москва' }
];

let genres = [
  { id: 1, name: 'Классика' }, { id: 2, name: 'Антиутопия' }, { id: 3, name: 'Фантастика' },
  { id: 4, name: 'Магический реализм' }, { id: 5, name: 'Исторический' }, { id: 6, name: 'Философия' }
];

let authors = [
  { id: 1, firstName: 'Лев', lastName: 'Толстой', country: 'Россия', birthYear: 1828 },
  { id: 2, firstName: 'Джордж', lastName: 'Оруэлл', country: 'Великобритания', birthYear: 1903 },
  { id: 3, firstName: 'Михаил', lastName: 'Булгаков', country: 'Россия', birthYear: 1891 },
  { id: 4, firstName: 'Фёдор', lastName: 'Достоевский', country: 'Россия', birthYear: 1821 },
  { id: 5, firstName: 'Рэй', lastName: 'Брэдбери', country: 'США', birthYear: 1920 }
];

function generateAccessToken(user) {
  const payload = {
    id: user.id,
    username: user.username,
    fullName: user.fullName,
    role: user.role,
    exp: Date.now() + ttlSeconds * 1000
  };
  return Buffer.from(JSON.stringify(payload)).toString('base64');
}

function verifyAccessToken(token) {
  try {
    const raw = Buffer.from(token, 'base64').toString('utf8');
    const payload = JSON.parse(raw);
    if (!payload.exp || Date.now() > payload.exp) return null;
    return payload;
  } catch (_) {
    return null;
  }
}

const server = http.createServer((req, res) => {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  };

  if (req.method === 'OPTIONS') {
    res.writeHead(204, corsHeaders);
    res.end();
    return;
  }

  const parsedUrl = url.parse(req.url, true);
  const cleanPath = (parsedUrl.pathname || '').replace(/^\/api/, '').replace(/\/+$/, '');
  const query = parsedUrl.query;
  const delay = parseInt(query.__delay || '0', 10);
  const fail = parseInt(query.__fail || '0', 10);

  let body = '';
  req.on('data', chunk => { body += chunk; });
  req.on('end', () => {
    setTimeout(() => {
      function sendJson(code, obj) {
        console.log(`[HTTP] ${req.method} ${parsedUrl.pathname} -> ${code}`);
        res.writeHead(code, {
          ...corsHeaders,
          'Content-Type': 'application/json; charset=utf-8'
        });
        res.end(JSON.stringify(obj));
      }

      if (fail > 0) {
        return sendJson(fail, { message: `Серверная ошибка ${fail}` });
      }

      let data = {};
      if (body) {
        try { data = JSON.parse(body); } catch (_) {}
      }

      const authHeader = req.headers['authorization'];
      let currentUser = null;
      if (authHeader && authHeader.startsWith('Bearer ')) {
        currentUser = verifyAccessToken(authHeader.substring(7));
      }

      // Регистрация
      if (cleanPath === '/auth/register' && req.method === 'POST') {
        const username = (data.username || '').trim();
        const password = (data.password || '').trim();
        const fullName = (data.fullName || '').trim() || username;

        if (!username || !password) {
          return sendJson(400, { message: 'Заполните логин и пароль' });
        }
        if (users.find(u => u.username.toLowerCase() === username.toLowerCase())) {
          return sendJson(409, { message: 'Пользователь с таким логином уже зарегистрирован' });
        }

        const newUser = {
          id: users.length + 1,
          username,
          password,
          fullName,
          role: 'reader'
        };
        users.push(newUser);

        const accessToken = generateAccessToken(newUser);
        const refreshToken = 'rt_' + Math.random().toString(36).substring(2) + Date.now();
        refreshTokensDb.add(refreshToken);

        return sendJson(200, {
          accessToken,
          refreshToken,
          user: { id: newUser.id, username: newUser.username, fullName: newUser.fullName, role: newUser.role }
        });
      }

      // Вход
      if (cleanPath === '/auth/login' && req.method === 'POST') {
        const username = (data.username || '').trim().toLowerCase();
        const password = (data.password || '').trim();

        const user = users.find(u => u.username.toLowerCase() === username && u.password === password);
        if (!user) {
          return sendJson(401, { message: 'Неверное имя пользователя или пароль' });
        }

        const accessToken = generateAccessToken(user);
        const refreshToken = 'rt_' + Math.random().toString(36).substring(2) + Date.now();
        refreshTokensDb.add(refreshToken);

        return sendJson(200, {
          accessToken,
          refreshToken,
          user: { id: user.id, username: user.username, fullName: user.fullName, role: user.role }
        });
      }

      // Проверка сессии
      if (cleanPath === '/auth/me' && req.method === 'GET') {
        if (!currentUser) {
          return sendJson(401, { message: 'Токен истек или недействителен' });
        }
        return sendJson(200, {
          id: currentUser.id,
          username: currentUser.username,
          fullName: currentUser.fullName,
          role: currentUser.role
        });
      }

      // Обновление токена
      if (cleanPath === '/auth/refresh' && req.method === 'POST') {
        const { refreshToken } = data;
        if (!refreshToken || !refreshTokensDb.has(refreshToken)) {
          return sendJson(401, { message: 'Недействительный токен обновления' });
        }
        const user = users[0];
        const newAccess = generateAccessToken(user);
        return sendJson(200, { accessToken: newAccess, refreshToken });
      }

      // Справочники
      if (cleanPath === '/publishers' && req.method === 'GET') return sendJson(200, publishers);
      if (cleanPath === '/genres' && req.method === 'GET') return sendJson(200, genres);
      if (cleanPath === '/authors' && req.method === 'GET') return sendJson(200, authors);

      // Книги
      if (cleanPath === '/books' && req.method === 'GET') {
        let result = books.filter(b => query.deleted === 'true' ? b.isDeleted : !b.isDeleted);
        if (query.search) {
          const s = query.search.toLowerCase();
          result = result.filter(b => b.title.toLowerCase().includes(s) || b.isbn.includes(s));
        }
        if (query.genreId) result = result.filter(b => b.genreIds.includes(parseInt(query.genreId, 10)));
        if (query.publisherId) result = result.filter(b => b.publisherId === parseInt(query.publisherId, 10));
        if (query.yearFrom) result = result.filter(b => b.year >= parseInt(query.yearFrom, 10));
        if (query.yearTo) result = result.filter(b => b.year <= parseInt(query.yearTo, 10));

        const page = parseInt(query.page || '1', 10);
        const size = parseInt(query.size || '10', 10);
        const start = (page - 1) * size;

        return sendJson(200, {
          items: result.slice(start, start + size),
          total: result.length,
          page,
          size
        });
      }

      // Пункт 17: Проверка прав на стороне сервера (Читателю запрещено модифицировать книги)
      if (cleanPath.startsWith('/books') && (req.method === 'POST' || req.method === 'PUT' || req.method === 'DELETE')) {
        if (currentUser && currentUser.role === 'reader') {
          return sendJson(403, { message: 'Доступ запрещен: у роли «Читатель» нет прав на модификацию фонда' });
        }
      }

      if (cleanPath === '/books' && req.method === 'POST') {
        if (books.some(b => b.isbn === data.isbn && !b.isDeleted)) {
          return sendJson(422, { field: 'isbn', message: 'Книга с таким ISBN уже существует на сервере' });
        }
        const newBook = { id: books.length + 1, ...data, isDeleted: false };
        books.push(newBook);
        return sendJson(201, newBook);
      }

      if (cleanPath.match(/^\/books\/\d+$/) && req.method === 'DELETE') {
        const id = parseInt(cleanPath.split('/').pop(), 10);
        const book = books.find(b => b.id === id);
        if (book) book.isDeleted = true;
        return sendJson(200, { success: true });
      }

      sendJson(404, { message: `Маршрут не найден: ${req.method} ${parsedUrl.pathname}` });
    }, delay);
  });
});

server.listen(PORT, () => {
  console.log(`[SERVER] Mock-сервер слушает http://localhost:${PORT} (TTL токена: ${ttlSeconds} сек)`);
});