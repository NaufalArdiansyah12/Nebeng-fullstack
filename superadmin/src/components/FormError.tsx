interface FormErrorProps {
  message?: string;
}

const FormError = ({ message }: FormErrorProps) => {
  if (!message) return null;

  return (
    <p className="text-sm text-destructive mt-1">{message}</p>
  );
};

export default FormError;
