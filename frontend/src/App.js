import Header from './components/Header';
import { Container } from '@material-ui/core';

function App() {
  return (
    <div className='App'>
      <Header />
      <Container maxWidth='md'>
        <h1>Hi!</h1>
      </Container>
    </div>
  );
}

export default App;
