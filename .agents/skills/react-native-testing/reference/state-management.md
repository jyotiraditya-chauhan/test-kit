# State Management Setup Per Library

Table of contents:
- [Zustand](#zustand)
- [Redux Toolkit](#redux-toolkit)
- [Jotai](#jotai)
- [MobX](#mobx)

`scripts/detect_stack.sh` reports which state-management library, if any,
is present. Use the matching pattern below. In every case, exercise the
real store in component/integration tests — do not mock the state library
itself, only the true I/O boundaries the store's actions call out to (a
network request, a native module).

## Zustand

Zustand stores are plain functions; reset state between tests rather than
mocking anything:

```tsx
import { useCartStore } from './cartStore';

beforeEach(() => {
  useCartStore.setState(useCartStore.getInitialState());
});

it('adds an item to the cart', () => {
  render(<AddToCartButton item={{ id: '1', price: 9.99 }} />);
  fireEvent.press(screen.getByRole('button', { name: /add to cart/i }));
  expect(useCartStore.getState().items).toHaveLength(1);
});
```

## Redux Toolkit

Wrap the component under test in a real `<Provider>` backed by a fresh
store created per test (a genuine store, not a mock), pre-seeded only with
the state the test actually needs:

```tsx
import { configureStore } from '@reduxjs/toolkit';
import { Provider } from 'react-redux';
import { cartReducer } from './cartSlice';

function renderWithStore(ui, preloadedState = {}) {
  const store = configureStore({
    reducer: { cart: cartReducer },
    preloadedState,
  });
  return render(<Provider store={store}>{ui}</Provider>);
}

it('shows the item count from the store', () => {
  renderWithStore(<CartBadge />, { cart: { items: [{ id: '1' }] } });
  expect(screen.getByText('1')).toBeTruthy();
});
```

## Jotai

Wrap in a `<Provider>` from `jotai` when the atoms need isolation between
tests (a fresh atom store per test), or set atom values directly via
`useHydrateAtoms`/`store.set` for a specific starting state:

```tsx
import { createStore, Provider } from 'jotai';
import { cartItemsAtom } from './atoms';

it('renders seeded cart items', () => {
  const store = createStore();
  store.set(cartItemsAtom, [{ id: '1', price: 9.99 }]);
  render(
    <Provider store={store}>
      <CartList />
    </Provider>
  );
  expect(screen.getByText(/9\.99/)).toBeTruthy();
});
```

## MobX

Observable stores are plain classes; instantiate a fresh one per test and
pass it in via props or a real `Provider` from `mobx-react`, wrapping
renders that read observables in `observer` as the app itself does:

```tsx
import { CartStore } from './CartStore';

it('reflects an added item in the badge', () => {
  const store = new CartStore();
  render(<CartBadge store={store} />);
  store.addItem({ id: '1', price: 9.99 });
  expect(screen.getByText('1')).toBeTruthy();
});
```
