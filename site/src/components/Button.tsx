import React from 'react';

export interface ButtonProps {}

export default function Button(
  props: ButtonProps
): React.FC<ButtonProps> {
  return (
    <button className="bg-amber-400 mt-4 p-2" onClick={() => console.log('button clicked!')}>
      {props.text}
    </button>
  );
}
